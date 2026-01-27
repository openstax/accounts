require 'rails_helper'

describe UpdateUserContactInfo, type: :routine do
  let!(:school) { FactoryBot.create :school, salesforce_id: 'SF_SCHOOL_001' }
  
  # Helper method to create a Salesforce contact mock
  def create_sf_contact(uuid:, faculty_verified:, contact_id: 'SF_CONTACT_001', school_id: 'SF_SCHOOL_001')
    contact = OpenStax::Salesforce::Remote::Contact.new(
      id: contact_id,
      accounts_uuid: uuid,
      faculty_verified: faculty_verified,
      school_type: 'College/University (4)',
      adoption_status: 'Not Adopter',
      grant_tutor_access: false
    )
    
    # Mock the school association
    sf_school = OpenStax::Salesforce::Remote::School.new(
      id: school_id,
      school_location: 'Domestic',
      is_kip: false,
      is_child_of_kip: false
    )
    allow(contact).to receive(:school).and_return(sf_school)
    allow(contact).to receive(:school_id).and_return(school_id)
    
    contact
  end

  # Helper method to stub the salesforce_contacts method
  def stub_salesforce_contacts(contacts)
    allow_any_instance_of(UpdateUserContactInfo).to receive(:salesforce_contacts).and_return(contacts)
  end

  # Helper method to stub Sentry methods
  def stub_sentry
    allow(Sentry).to receive(:capture_check_in).and_return('check_in_id')
    allow(Sentry).to receive(:capture_message)
  end

  describe 'faculty status preservation logic' do
    before { stub_sentry }
    context 'when user has confirmed_faculty status' do
      let!(:user) { FactoryBot.create :user, faculty_status: :confirmed_faculty, uuid: 'test-uuid-001' }

      it 'does not downgrade to pending_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'pending_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('confirmed_faculty')
      end

      it 'does not downgrade to incomplete_signup' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'incomplete_signup')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('confirmed_faculty')
      end

      it 'does not downgrade to no_faculty_info' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'no_faculty_info')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('confirmed_faculty')
      end

      it 'does not downgrade when faculty_verified is nil' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: nil)
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('confirmed_faculty')
      end

      it 'allows update to rejected_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'rejected_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('rejected_faculty')
      end

      it 'allows update to rejected_by_sheerid' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'rejected_by_sheerid')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('rejected_by_sheerid')
      end

      it 'preserves confirmed_faculty when already confirmed in Salesforce' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'confirmed_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('confirmed_faculty')
      end
    end

    context 'when user has pending_faculty status' do
      let!(:user) { FactoryBot.create :user, faculty_status: :pending_faculty, uuid: 'test-uuid-002' }

      it 'does not downgrade to incomplete_signup' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'incomplete_signup')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('pending_faculty')
      end

      it 'does not downgrade to no_faculty_info' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'no_faculty_info')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('pending_faculty')
      end

      it 'does not downgrade when faculty_verified is nil' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: nil)
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('pending_faculty')
      end

      it 'allows upgrade to confirmed_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'confirmed_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('confirmed_faculty')
      end

      it 'allows update to rejected_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'rejected_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('rejected_faculty')
      end

      it 'allows update to rejected_by_sheerid' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'rejected_by_sheerid')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('rejected_by_sheerid')
      end
    end

    context 'when user has rejected_faculty status' do
      let!(:user) { FactoryBot.create :user, faculty_status: :rejected_faculty, uuid: 'test-uuid-003' }

      it 'allows update to confirmed_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'confirmed_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('confirmed_faculty')
      end

      it 'allows update to pending_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'pending_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('pending_faculty')
      end

      it 'allows update to no_faculty_info' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'no_faculty_info')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('no_faculty_info')
      end
    end

    context 'when user has rejected_by_sheerid status' do
      let!(:user) { FactoryBot.create :user, faculty_status: :rejected_by_sheerid, uuid: 'test-uuid-004' }

      it 'allows update to confirmed_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'confirmed_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('confirmed_faculty')
      end

      it 'allows update to pending_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'pending_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('pending_faculty')
      end
    end

    context 'when user has incomplete_signup status' do
      let!(:user) { FactoryBot.create :user, faculty_status: :incomplete_signup, uuid: 'test-uuid-005' }

      it 'allows update to confirmed_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'confirmed_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('confirmed_faculty')
      end

      it 'allows update to pending_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'pending_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('pending_faculty')
      end

      it 'allows update to no_faculty_info' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'no_faculty_info')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('no_faculty_info')
      end
    end

    context 'when user has no_faculty_info status' do
      let!(:user) { FactoryBot.create :user, faculty_status: :no_faculty_info, uuid: 'test-uuid-006' }

      it 'allows update to confirmed_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'confirmed_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('confirmed_faculty')
      end

      it 'allows update to pending_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'pending_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('pending_faculty')
      end
    end
  end

  describe 'SecurityLog creation for faculty status changes' do
    before { stub_sentry }
    let!(:user) { FactoryBot.create :user, faculty_status: :no_faculty_info, uuid: 'test-uuid-007' }

    it 'creates a SecurityLog when faculty status changes' do
      sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'confirmed_faculty')
      stub_salesforce_contacts([sf_contact])

      expect {
        described_class.call
      }.to change { SecurityLog.count }.by(1)

      log = SecurityLog.last
      expect(log.event_type).to eq('salesforce_updated_faculty_status')
      expect(log.event_data['old_status']).to eq('no_faculty_info')
      expect(log.event_data['new_status']).to eq('confirmed_faculty')
    end

    it 'does not create a SecurityLog when faculty status is preserved' do
      user.update!(faculty_status: :confirmed_faculty)
      sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'pending_faculty')
      stub_salesforce_contacts([sf_contact])

      # Only expecting contact_id update log, not faculty status log
      expect {
        described_class.call
      }.to change { SecurityLog.count }.by(1)

      log = SecurityLog.last
      expect(log.event_type).to eq('user_contact_id_updated_from_salesforce')
    end
  end

  describe 'unknown faculty_verified value handling' do
    before { stub_sentry }
    let!(:user) { FactoryBot.create :user, faculty_status: :no_faculty_info, uuid: 'test-uuid-008' }

    it 'raises an error for unknown faculty_verified values' do
      sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'unknown_status')
      stub_salesforce_contacts([sf_contact])

      expect {
        described_class.call
      }.to raise_error(UpdateUserContactInfo::UnknownFacultyVerifiedError, /Unknown faculty_verified field/)
    end

    it 'captures error message to Sentry before raising' do
      sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'invalid_value')
      stub_salesforce_contacts([sf_contact])

      expect(Sentry).to receive(:capture_message).with(/Unknown faculty_verified field/)

      expect {
        described_class.call
      }.to raise_error
    end
  end
end
