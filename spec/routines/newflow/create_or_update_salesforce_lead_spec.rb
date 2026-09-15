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

    describe 'when lead save fails' do
      it 'logs to SecurityLog and Sentry' do
        allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).with(accounts_uuid: user.uuid).and_return(nil)
        allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).with(email: user.best_email_address_for_salesforce).and_return(nil)

        mock_lead = OpenStax::Salesforce::Remote::Lead.new(email: user.best_email_address_for_salesforce)
        allow(OpenStax::Salesforce::Remote::Lead).to receive(:new).and_return(mock_lead)
        allow(mock_lead).to receive(:save).and_return(false)
        allow(mock_lead).to receive(:errors).and_return(double(full_messages: ['Some SF error']))

        described_class.call(user: user)

        expect(SecurityLog.where(event_type: :salesforce_lead_save_failed).count).to eq(1)
        expect(Sentry).to have_received(:capture_message).with(/Salesforce lead save failed for user #{user.id}/)
      end
    end

    describe 'when the school salesforce_id is stale (cross-reference error)' do
      let!(:stale_school) { FactoryBot.create :school, salesforce_id: '0010v0StaleAcct' }
      let(:mock_lead) { OpenStax::Salesforce::Remote::Lead.new(email: user.best_email_address_for_salesforce) }
      let(:cross_reference_error) do
        double(full_messages: [
          'INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY: ' \
          'insufficient access rights on cross-reference id: 0010v0StaleAcct'
        ])
      end

      before do
        user.update!(school: stale_school)
        allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).and_return(nil)
        allow(OpenStax::Salesforce::Remote::Lead).to receive(:new).and_return(mock_lead)
        allow(mock_lead).to receive(:id).and_return('SF_LEAD_RETRY')
        allow(mock_lead).to receive(:errors).and_return(cross_reference_error)
      end

      it 'retries the save with the fallback school so the lead is not lost' do
        save_results = [false, true]
        allow(mock_lead).to receive(:save) { save_results.shift }

        described_class.call(user: user)

        expect(mock_lead.account_id).to eq('SF_SCHOOL_HOME')
        expect(mock_lead.school_id).to eq('SF_SCHOOL_HOME')
        expect(user.reload.salesforce_lead_id).to eq('SF_LEAD_RETRY')
        expect(SecurityLog.where(event_type: :salesforce_lead_save_failed).count).to eq(0)
        expect(Sentry).to have_received(:capture_message).with(
          /Invalid school \(0010v0StaleAcct\) for user \(#{user.id}\); retrying/,
          level: :warning
        )
      end

      it 'still logs the failure when the retry also fails' do
        allow(mock_lead).to receive(:save).and_return(false)

        described_class.call(user: user)

        expect(SecurityLog.where(event_type: :salesforce_lead_save_failed).count).to eq(1)
        expect(Sentry).to have_received(:capture_message).with(
          /Salesforce lead save failed for user #{user.id}/
        )
      end
    end

    describe 'when user already has a contact' do
      let(:existing_contact) do
        contact = OpenStax::Salesforce::Remote::Contact.new(email: user.best_email_address_for_salesforce)
        allow(contact).to receive(:id).and_return('SF_CONTACT_123')
        allow(contact).to receive(:save).and_return(true)
        contact
      end

      before do
        user.update!(salesforce_contact_id: 'SF_CONTACT_123', expected_start_semester: 'next_semester')
        allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).and_return(nil)
        allow(OpenStax::Salesforce::Remote::Contact).to receive(:find).with('SF_CONTACT_123').and_return(existing_contact)
      end

      it 'writes the signup profile to the contact instead of creating a lead' do
        result = described_class.call(user: user)

        expect(result.outputs.lead).to be_nil
        expect(result.outputs.contact).to eq(existing_contact)
        expect(existing_contact).to have_received(:save)
        expect(existing_contact.role).to eq('Instructor')
        expect(existing_contact.position).to eq('instructor')
        expect(existing_contact.who_chooses_books).to eq('instructor')
        expect(existing_contact.subject_interest).to eq('AP Macro Econ')
        expect(existing_contact.num_students).to eq('35')
        expect(existing_contact.expected_start_semester).to eq('Next semester')
        expect(existing_contact.adoption_json).to be_nil
        expect(existing_contact.os_accounts_id).to eq(user.id)
        expect(existing_contact.accounts_uuid).to eq(user.uuid)
        expect(existing_contact.newsletter_opt_in).to eq(false)
        expect(SecurityLog.where(event_type: :user_already_has_contact_not_creating_lead).count).to eq(1)
        expect(SecurityLog.where(event_type: :updated_salesforce_contact).count).to eq(1)
        expect(SecurityLog.where(event_type: :creating_new_salesforce_lead).count).to eq(0)
      end

      it 'leaves the CX-owned contact fields alone' do
        described_class.call(user: user)

        expect(existing_contact.faculty_verified).to be_nil
        expect(existing_contact.adoption_status).to be_nil
        expect(existing_contact.first_name).to be_nil
        expect(existing_contact.school_id).to be_nil
      end

      it 'logs when the contact save fails' do
        allow(existing_contact).to receive(:save).and_return(false)
        allow(existing_contact).to receive(:errors).and_return(double(full_messages: ['INVALID_FIELD']))

        described_class.call(user: user)

        expect(SecurityLog.where(event_type: :salesforce_contact_save_failed).count).to eq(1)
        expect(Sentry).to have_received(:capture_message).with(/Salesforce contact save failed for user #{user.id}/)
      end
    end

    describe 'when the lead was converted into a contact' do
      let(:converted_lead) do
        lead = OpenStax::Salesforce::Remote::Lead.new(email: user.best_email_address_for_salesforce)
        allow(lead).to receive(:id).and_return('SF_LEAD_CONVERTED')
        lead.is_converted = true
        lead.converted_contact_id = 'SF_CONTACT_FROM_LEAD'
        lead
      end
      let(:contact) do
        contact = OpenStax::Salesforce::Remote::Contact.new(email: user.best_email_address_for_salesforce)
        allow(contact).to receive(:id).and_return('SF_CONTACT_FROM_LEAD')
        allow(contact).to receive(:save).and_return(true)
        contact
      end

      before do
        user.update!(salesforce_lead_id: 'SF_LEAD_CONVERTED')
        allow(OpenStax::Salesforce::Remote::Lead).to receive(:find).with('SF_LEAD_CONVERTED').and_return(converted_lead)
        allow(OpenStax::Salesforce::Remote::Contact).to receive(:find).with('SF_CONTACT_FROM_LEAD').and_return(contact)
      end

      it 'follows the conversion and writes the contact, not the lead' do
        expect(converted_lead).not_to receive(:save)

        result = described_class.call(user: user)

        expect(user.reload.salesforce_contact_id).to eq('SF_CONTACT_FROM_LEAD')
        expect(user.salesforce_lead_id).to eq('SF_LEAD_CONVERTED')
        expect(result.outputs.contact).to eq(contact)
        expect(contact).to have_received(:save)
        expect(SecurityLog.where(event_type: :salesforce_lead_already_converted).count).to eq(1)
        expect(SecurityLog.where(event_type: :updated_salesforce_contact).count).to eq(1)
        expect(SecurityLog.where(event_type: :creating_new_salesforce_lead).count).to eq(0)
      end
    end

    describe 'expected_start_semester assignment' do
      let(:mock_lead) do
        lead = OpenStax::Salesforce::Remote::Lead.new(email: user.best_email_address_for_salesforce)
        allow(lead).to receive(:save).and_return(true)
        allow(lead).to receive(:id).and_return('SF_LEAD_999')
        lead
      end

      before do
        allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).and_return(nil)
        allow(OpenStax::Salesforce::Remote::Lead).to receive(:new).and_return(mock_lead)
      end

      [
        ['this_semester',      'This semester'],
        ['next_semester',      'Next semester'],
        ['next_academic_year', 'Next academic year'],
        ['just_exploring',     'Just exploring']
      ].each do |db_value, expected_label|
        it "maps #{db_value.inspect} to #{expected_label.inspect}" do
          user.update_column(:expected_start_semester, db_value)
          described_class.call(user: user)
          expect(mock_lead.expected_start_semester).to eq(expected_label)
        end
      end

      it 'assigns nil when user.expected_start_semester is nil' do
        user.update_column(:expected_start_semester, nil)

        described_class.call(user: user)

        expect(mock_lead.expected_start_semester).to be_nil
      end

      it 'assigns nil when user.expected_start_semester is an unrecognized value' do
        user.update_column(:expected_start_semester, 'garbage')

        described_class.call(user: user)

        expect(mock_lead.expected_start_semester).to be_nil
      end
    end
  end
end
