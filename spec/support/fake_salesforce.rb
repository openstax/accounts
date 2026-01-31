# frozen_string_literal: true

# FakeSalesforce provides in-memory stubs for OpenStax::Salesforce::Remote classes,
# eliminating the need for VCR cassettes in specs that interact with Salesforce.
#
# Usage in specs:
#
#   # In spec file or spec_helper:
#   require 'support/fake_salesforce'
#
#   RSpec.describe 'Something with Salesforce' do
#     include FakeSalesforce::SpecHelpers
#
#     before do
#       stub_salesforce!
#     end
#
#     it 'can find a contact' do
#       contact = fake_salesforce_contact(id: 'abc123', first_name: 'John', last_name: 'Doe')
#       expect(OpenStax::Salesforce::Remote::Contact.find('abc123')).to eq(contact)
#     end
#   end
#
module FakeSalesforce
  # In-memory store for fake Salesforce records
  class Store
    attr_reader :records

    def initialize
      @records = {}
      @id_counter = 0
    end

    def reset!
      @records = {}
      @id_counter = 0
    end

    def add(klass, record)
      @records[klass] ||= {}
      record.id ||= generate_id
      @records[klass][record.id] = record
      record
    end

    def find(klass, id)
      @records.dig(klass, id)
    end

    def find_by(klass, conditions)
      all(klass).find do |record|
        conditions.all? { |key, value| record.send(key) == value }
      end
    end

    def where(klass, conditions)
      all(klass).select do |record|
        conditions.all? { |key, value| record.send(key) == value }
      end
    end

    def all(klass)
      (@records[klass] || {}).values
    end

    def generate_id
      @id_counter += 1
      # Salesforce IDs are 18-character alphanumeric strings
      "FAKE#{@id_counter.to_s.rjust(14, '0')}"
    end
  end

  # Fake query builder that mimics ActiveForce's query interface
  class FakeQuery
    include Enumerable

    def initialize(store, klass, conditions = {})
      @store = store
      @klass = klass
      @conditions = conditions
    end

    def where(new_conditions_or_soql = {})
      if new_conditions_or_soql.is_a?(String)
        # Ignore SOQL strings - just return self for chaining
        self
      else
        FakeQuery.new(@store, @klass, @conditions.merge(new_conditions_or_soql))
      end
    end

    def to_a
      if @conditions.empty?
        @store.all(@klass)
      else
        @store.where(@klass, @conditions)
      end
    end

    def each(&block)
      to_a.each(&block)
    end

    def first
      to_a.first
    end
  end

  # Module to be included in specs
  module SpecHelpers
    def self.included(base)
      base.let(:fake_salesforce_store) { FakeSalesforce::Store.new }
    end

    # Call this in a before block to stub all Salesforce Remote classes
    def stub_salesforce!
      stub_salesforce_class(OpenStax::Salesforce::Remote::Contact)
      stub_salesforce_class(OpenStax::Salesforce::Remote::Lead)
      stub_salesforce_class(OpenStax::Salesforce::Remote::School)
      stub_salesforce_class(OpenStax::Salesforce::Remote::Book) if defined?(OpenStax::Salesforce::Remote::Book)
      stub_salesforce_class(OpenStax::Salesforce::Remote::Campaign) if defined?(OpenStax::Salesforce::Remote::Campaign)
      stub_salesforce_class(OpenStax::Salesforce::Remote::CampaignMember) if defined?(OpenStax::Salesforce::Remote::CampaignMember)
    end

    def stub_salesforce_class(klass)
      store = fake_salesforce_store

      # Stub .find to look up by ID
      allow(klass).to receive(:find) do |id|
        store.find(klass, id)
      end

      # Stub .find_by to look up by conditions
      allow(klass).to receive(:find_by) do |conditions|
        store.find_by(klass, conditions)
      end

      # Stub .where to return a query object
      allow(klass).to receive(:where) do |conditions|
        FakeQuery.new(store, klass, conditions)
      end

      # Stub .all to return all records
      allow(klass).to receive(:all) do
        store.all(klass)
      end

      # Stub .query to return a query object (used by some specs)
      allow(klass).to receive(:query) do
        FakeQuery.new(store, klass)
      end

      # Stub .new to create instances that save to our store
      allow(klass).to receive(:new).and_wrap_original do |original_method, *args, &block|
        instance = original_method.call(*args, &block)
        stub_salesforce_instance(instance, store)
        instance
      end
    end

    def stub_salesforce_instance(instance, store)
      klass = instance.class

      # Stub save to add to store and return true
      allow(instance).to receive(:save) do
        store.add(klass, instance)
        true
      end

      # Stub save! to add to store or raise
      allow(instance).to receive(:save!) do
        store.add(klass, instance)
        instance
      end

      # Stub errors to return empty errors object
      fake_errors = double('errors', any?: false, messages: {}, full_messages: [], inspect: '')
      allow(instance).to receive(:errors).and_return(fake_errors)
    end

    # Helper methods to create fake records

    def fake_salesforce_contact(attrs = {})
      contact = OpenStax::Salesforce::Remote::Contact.new
      apply_attrs(contact, attrs)
      fake_salesforce_store.add(OpenStax::Salesforce::Remote::Contact, contact)
      contact
    end

    def fake_salesforce_lead(attrs = {})
      lead = OpenStax::Salesforce::Remote::Lead.new
      apply_attrs(lead, attrs)
      fake_salesforce_store.add(OpenStax::Salesforce::Remote::Lead, lead)
      lead
    end

    def fake_salesforce_school(attrs = {})
      school = OpenStax::Salesforce::Remote::School.new
      apply_attrs(school, attrs)
      fake_salesforce_store.add(OpenStax::Salesforce::Remote::School, school)
      school
    end

    private

    def apply_attrs(record, attrs)
      attrs.each do |key, value|
        record.send("#{key}=", value) if record.respond_to?("#{key}=")
      end
      # Set id directly if provided (id= may not exist)
      if attrs[:id]
        record.instance_variable_set(:@id, attrs[:id])
        # Also define a getter if it doesn't exist
        unless record.respond_to?(:id)
          record.define_singleton_method(:id) { @id }
        end
      end
    end
  end
end
