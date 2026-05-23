require 'rails_helper'

RSpec.describe Salesforce::Records::School do
  it 'maps to the Account SObject' do
    expect(described_class.table_name).to eq('Account')
  end

  %i[
    id name city state country type school_location sheerid_school_name
    is_kip is_child_of_kip total_school_enrollment has_assignable_contacts
  ].each do |attr|
    it "responds to ##{attr}" do
      expect(described_class.new).to respond_to(attr)
    end
  end
end
