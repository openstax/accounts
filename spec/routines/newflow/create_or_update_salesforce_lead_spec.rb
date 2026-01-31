require 'rails_helper'
require 'support/fake_salesforce'

module Newflow
  describe CreateOrUpdateSalesforceLead, type: :routine do
    include FakeSalesforce::SpecHelpers

    before do
      stub_salesforce!

      # The routine needs a "Find Me A Home" school when user has no school
      # Create the local School record first
      local_school = FactoryBot.create(:school, name: 'Find Me A Home')

      # Then add it to the fake Salesforce store
      fake_salesforce_school(
        id: local_school.salesforce_id,
        name: 'Find Me A Home'
      )
    end

    let(:user) do
      User.create do |u|
        u.first_name = "Max"
        u.last_name = "Liebermann"
        u.state = "activated"
        u.faculty_status = "pending_faculty"
        u.self_reported_school = "Test University"
        u.role = "instructor"
        u.school_type = "unknown_school_type"
        u.using_openstax = false
        u.receive_newsletter = false
        u.is_newflow = true
        u.phone_number = "+17133484799"
        u.school_location = "unknown_school_location"
        u.opt_out_of_cookies = false
        u.how_many_students = "35"
        u.which_books = "AP Macro Econ"
        u.who_chooses_books = "instructor"
        u.using_openstax_how = "as_primary"
        u.is_profile_complete = true
      end
    end

    it 'works on the happy path' do
      expect(Rails.logger).not_to receive(:warn)

      lead = described_class[user: user]

      expect(user.salesforce_lead_id).not_to be_nil
    end

    it 'creates a lead with the correct attributes' do
      described_class[user: user]

      # Verify a lead was created
      leads = fake_salesforce_store.all(OpenStax::Salesforce::Remote::Lead)
      expect(leads.size).to eq(1)

      lead = leads.first
      expect(lead.first_name).to eq('Max')
      expect(lead.last_name).to eq('Liebermann')
      expect(lead.phone).to eq('+17133484799')
    end

    context 'when user already has a salesforce_lead_id' do
      before do
        # Pre-create a lead in the fake store
        fake_salesforce_lead(
          id: 'EXISTINGLEAD001',
          email: user.best_email_address_for_salesforce,
          first_name: 'Old',
          last_name: 'Name'
        )
        user.update!(salesforce_lead_id: 'EXISTINGLEAD001')
      end

      it 'updates the existing lead' do
        described_class[user: user]

        lead = fake_salesforce_store.find(OpenStax::Salesforce::Remote::Lead, 'EXISTINGLEAD001')
        expect(lead.first_name).to eq('Max')
        expect(lead.last_name).to eq('Liebermann')
      end
    end
  end
end
