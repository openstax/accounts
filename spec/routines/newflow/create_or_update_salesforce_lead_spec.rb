require 'rails_helper'

module Newflow
  describe CreateOrUpdateSalesforceLead, type: :routine do
    let!(:home_school) do
      FactoryBot.create :school, name: 'Find Me A Home', salesforce_id: 'SF_SCHOOL_HOME'
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

    before do
      stub_sentry
      allow(Salesforce::Records::School).to receive(:find_by)
        .with({ name: 'Find Me A Home' })
        .and_return(OpenStruct.new(id: 'SF_SCHOOL_HOME'))
    end

    describe 'creating a new lead' do
      it 'creates a new lead when none exists and saves the lead id' do
        allow(Salesforce::Records::Lead).to receive(:find_by).with({ accounts_uuid: user.uuid }).and_return(nil)
        allow(Salesforce::Records::Lead).to receive(:find_by).with({ email: user.best_email_address_for_salesforce }).and_return(nil)

        mock_lead = Salesforce::Records::Lead.new(email: user.best_email_address_for_salesforce, accounts_uuid: user.uuid)
        allow(Salesforce::Records::Lead).to receive(:new).and_return(mock_lead)
        allow(mock_lead).to receive(:save).and_return(true)
        allow(mock_lead).to receive(:id).and_return('SF_LEAD_123')

        described_class.call(user: user)

        expect(user.reload.salesforce_lead_id).to eq('SF_LEAD_123')
        expect(SecurityLog.where(event_type: 'salesforce_upsert_lead_saved', user: user).count).to eq(1)
      end
    end

    describe 'finding existing leads' do
      let(:existing_lead) do
        lead = Salesforce::Records::Lead.new(email: user.best_email_address_for_salesforce, accounts_uuid: user.uuid)
        allow(lead).to receive(:id).and_return('SF_LEAD_EXISTING')
        allow(lead).to receive(:save).and_return(true)
        lead
      end

      it 'finds and updates existing lead by UUID' do
        allow(Salesforce::Records::Lead).to receive(:find_by).with({ accounts_uuid: user.uuid }).and_return(existing_lead)

        described_class.call(user: user)

        expect(user.reload.salesforce_lead_id).to eq('SF_LEAD_EXISTING')
        expect(SecurityLog.where(event_type: 'salesforce_lookup_matched_by_uuid', user: user).count).to eq(1)
      end

      it 'finds and updates existing lead by email when UUID search fails' do
        allow(user).to receive(:best_email_address_for_salesforce).and_return('max@example.com')
        allow(Salesforce::Records::Lead).to receive(:find_by).with({ accounts_uuid: user.uuid }).and_return(nil)
        allow(Salesforce::Records::Lead).to receive(:find_by).with({ email: 'max@example.com' }).and_return(existing_lead)
        # User must be findable by id (UpsertLead doesn't go through the User class directly,
        # but ActiveRecord-side persistence needs to keep working)
        allow(User).to receive(:find).and_return(user)

        described_class.call(user: user)

        expect(user.reload.salesforce_lead_id).to eq('SF_LEAD_EXISTING')
        expect(SecurityLog.where(event_type: 'salesforce_lookup_matched_by_email', user: user).count).to eq(1)
      end

      it 'uses stored lead ID if available and it still owns the user' do
        user.update_column(:salesforce_lead_id, 'SF_LEAD_STORED')
        allow(existing_lead).to receive(:id).and_return('SF_LEAD_STORED')
        allow(Salesforce::Records::Lead).to receive(:find).with('SF_LEAD_STORED').and_return(existing_lead)

        described_class.call(user: user)

        expect(user.reload.salesforce_lead_id).to eq('SF_LEAD_STORED')
        expect(SecurityLog.where(event_type: 'salesforce_lookup_matched_by_stored_id', user: user).count).to eq(1)
        expect(SecurityLog.where(event_type: 'salesforce_lookup_matched_by_uuid', user: user).count).to eq(0)
        expect(SecurityLog.where(event_type: 'salesforce_lookup_matched_by_email', user: user).count).to eq(0)
      end
    end

    describe 'when lead save fails' do
      it 'logs to SecurityLog and Sentry' do
        allow(Salesforce::Records::Lead).to receive(:find_by).with({ accounts_uuid: user.uuid }).and_return(nil)
        allow(Salesforce::Records::Lead).to receive(:find_by).with({ email: user.best_email_address_for_salesforce }).and_return(nil)

        mock_lead = Salesforce::Records::Lead.new(email: user.best_email_address_for_salesforce, accounts_uuid: user.uuid)
        allow(Salesforce::Records::Lead).to receive(:new).and_return(mock_lead)
        allow(mock_lead).to receive(:save).and_return(false)
        allow(mock_lead).to receive(:errors).and_return(double(full_messages: ['Some SF error']))

        described_class.call(user: user)

        expect(SecurityLog.where(event_type: 'salesforce_upsert_lead_save_failed', user: user).count).to eq(1)
        expect(Sentry).to have_received(:capture_message).with(/Salesforce lead save failed for user #{user.id}/)
      end
    end

    describe 'when user already has a contact that still owns them' do
      let(:owning_contact) do
        Salesforce::Records::Contact.new(
          id: 'SF_CONTACT_123', accounts_uuid: user.uuid,
          master_record_id: nil, is_deleted: false
        )
      end

      it 'does not create a lead' do
        user.update_column(:salesforce_contact_id, 'SF_CONTACT_123')

        allow(Salesforce::Records::Lead).to receive(:find_by).with({ accounts_uuid: user.uuid }).and_return(nil)
        allow(Salesforce::Records::Lead).to receive(:find_by).with({ email: user.best_email_address_for_salesforce }).and_return(nil)
        allow(Salesforce::Records::Contact).to receive(:find).with('SF_CONTACT_123').and_return(owning_contact)

        expect(Salesforce::Records::Lead).not_to receive(:new)
        described_class.call(user: user)

        expect(SecurityLog.where(event_type: 'salesforce_upsert_lead_skipped_user_has_contact', user: user).count).to eq(1)
      end
    end

    describe 'when stored contact_id no longer owns the user' do
      it 'clears the stored contact_id and proceeds to create a lead' do
        user.update_column(:salesforce_contact_id, 'SF_CONTACT_STALE')

        # Stored contact lookup returns a contact that doesn't own this user
        foreign_contact = Salesforce::Records::Contact.new(
          id: 'SF_CONTACT_STALE', accounts_uuid: 'OTHER',
          master_record_id: nil, is_deleted: false
        )
        allow(Salesforce::Records::Contact).to receive(:find).with('SF_CONTACT_STALE').and_return(foreign_contact)
        # UUID-based contact lookup also returns nothing for this user
        allow(Salesforce::Records::Contact).to receive(:find_by).with({ accounts_uuid: user.uuid }).and_return(nil)

        allow(Salesforce::Records::Lead).to receive(:find_by).with({ accounts_uuid: user.uuid }).and_return(nil)
        allow(Salesforce::Records::Lead).to receive(:find_by).with({ email: user.best_email_address_for_salesforce }).and_return(nil)

        mock_lead = Salesforce::Records::Lead.new(email: user.best_email_address_for_salesforce, accounts_uuid: user.uuid)
        allow(Salesforce::Records::Lead).to receive(:new).and_return(mock_lead)
        allow(mock_lead).to receive(:save).and_return(true)
        allow(mock_lead).to receive(:id).and_return('SF_LEAD_NEW')

        described_class.call(user: user)

        expect(user.reload.salesforce_contact_id).to be_nil
        expect(user.reload.salesforce_lead_id).to eq('SF_LEAD_NEW')
        expect(SecurityLog.where(event_type: 'salesforce_stale_contact_id_cleared', user: user).count).to eq(1)
      end
    end

    describe 'expected_start_semester assignment' do
      let(:mock_lead) do
        lead = Salesforce::Records::Lead.new(email: user.best_email_address_for_salesforce, accounts_uuid: user.uuid)
        allow(lead).to receive(:save).and_return(true)
        allow(lead).to receive(:id).and_return('SF_LEAD_999')
        lead
      end

      before do
        allow(Salesforce::Records::Lead).to receive(:find_by).and_return(nil)
        allow(Salesforce::Records::Lead).to receive(:new).and_return(mock_lead)
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
