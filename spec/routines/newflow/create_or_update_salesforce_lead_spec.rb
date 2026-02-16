require 'rails_helper'

module Newflow
  describe CreateOrUpdateSalesforceLead, type: :routine do
    let!(:school) { FactoryBot.create :school, name: 'Find Me A Home', salesforce_id: 'SF_SCHOOL_HOME' }

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

    before do
      stub_sentry
      # Stub the school lookup
      allow(OpenStax::Salesforce::Remote::School).to receive(:find_by).with(name: 'Find Me A Home')
        .and_return(OpenStruct.new(id: 'SF_SCHOOL_HOME'))
    end

    describe 'creating a new lead' do
      it 'creates a new lead when none exists' do
        # Stub all the search methods to return nil (no existing lead)
        allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).with(accounts_uuid: user.uuid).and_return(nil)
        allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).with(email: user.best_email_address_for_salesforce).and_return(nil)

        # Create a mock lead that will be "saved"
        mock_lead = OpenStax::Salesforce::Remote::Lead.new(email: user.best_email_address_for_salesforce)
        allow(OpenStax::Salesforce::Remote::Lead).to receive(:new).and_return(mock_lead)
        allow(mock_lead).to receive(:save).and_return(true)
        allow(mock_lead).to receive(:id).and_return('SF_LEAD_123')

        described_class.call(user: user)

        expect(user.salesforce_lead_id).to eq('SF_LEAD_123')
        expect(SecurityLog.where(event_type: :creating_new_salesforce_lead).count).to eq(1)
      end
    end

    describe 'finding existing leads' do
      let(:existing_lead) do
        lead = OpenStax::Salesforce::Remote::Lead.new(email: user.best_email_address_for_salesforce)
        allow(lead).to receive(:id).and_return('SF_LEAD_EXISTING')
        allow(lead).to receive(:save).and_return(true)
        lead
      end

      it 'finds and updates existing lead by UUID' do
        # Stub to return existing lead when searched by UUID
        allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).with(accounts_uuid: user.uuid).and_return(existing_lead)

        described_class.call(user: user)

        expect(user.salesforce_lead_id).to eq('SF_LEAD_EXISTING')
        expect(SecurityLog.where(event_type: :salesforce_lead_found_by_uuid).count).to eq(1)
        expect(SecurityLog.where(event_type: :creating_new_salesforce_lead).count).to eq(0)
      end

      it 'finds and updates existing lead by email when UUID search fails' do
        # Stub UUID search to return nil, email search to return existing lead
        allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).with(accounts_uuid: user.uuid).and_return(nil)
        allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).with(email: user.best_email_address_for_salesforce).and_return(existing_lead)

        described_class.call(user: user)

        expect(user.salesforce_lead_id).to eq('SF_LEAD_EXISTING')
        expect(SecurityLog.where(event_type: :salesforce_lead_found_by_email).count).to eq(1)
        expect(SecurityLog.where(event_type: :creating_new_salesforce_lead).count).to eq(0)
      end

      it 'uses stored lead ID if available' do
        user.salesforce_lead_id = 'SF_LEAD_STORED'
        user.save!

        # Stub to return existing lead when searched by ID
        allow(OpenStax::Salesforce::Remote::Lead).to receive(:find).with('SF_LEAD_STORED').and_return(existing_lead)
        allow(existing_lead).to receive(:id).and_return('SF_LEAD_STORED')

        described_class.call(user: user)

        expect(user.salesforce_lead_id).to eq('SF_LEAD_STORED')
        # Should not search by UUID or email since it found by ID
        expect(SecurityLog.where(event_type: :salesforce_lead_found_by_uuid).count).to eq(0)
        expect(SecurityLog.where(event_type: :salesforce_lead_found_by_email).count).to eq(0)
      end
    end

    describe 'when user already has a contact' do
      let(:existing_contact) do
        contact = OpenStruct.new(id: 'SF_CONTACT_123')
        contact
      end

      it 'does not create a lead if user already has a contact' do
        user.salesforce_contact_id = 'SF_CONTACT_123'
        user.save!

        # Stub all lead searches to return nil
        allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).with(accounts_uuid: user.uuid).and_return(nil)
        allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).with(email: user.best_email_address_for_salesforce).and_return(nil)

        # Stub contact lookup to return existing contact
        allow(OpenStax::Salesforce::Remote::Contact).to receive(:find).with('SF_CONTACT_123').and_return(existing_contact)

        result = described_class.call(user: user)

        expect(result.outputs.lead).to be_nil
        expect(SecurityLog.where(event_type: :user_already_has_contact_not_creating_lead).count).to eq(1)
        expect(SecurityLog.where(event_type: :creating_new_salesforce_lead).count).to eq(0)
      end
    end
  end
end
