require 'rails_helper'

describe SheeridVerification, type: :model do
  describe '#faculty_status_for_step' do
    {
      'success' => User::CONFIRMED_FACULTY,
      'rejected' => User::REJECTED_BY_SHEERID,
      'docUpload' => User::PENDING_SHEERID,
      'pending' => User::PENDING_SHEERID,
      'collectTeacherPersonalInfo' => User::PENDING_SHEERID,
      'emailLoop' => User::PENDING_SHEERID,
      'sso' => User::PENDING_SHEERID,
      'somethingSheerIDInventsLater' => User::PENDING_SHEERID,
    }.each do |current_step, expected_status|
      it "maps currentStep #{current_step.inspect} to #{expected_status.inspect}" do
        verification = FactoryBot.build(:sheerid_verification, current_step: current_step)
        expect(verification.faculty_status_for_step).to eq(expected_status)
      end
    end

    it 'maps an error step whose only error id is expiredVerification to sheerid_expired' do
      verification = FactoryBot.build(
        :sheerid_verification, current_step: 'error', error_ids: ['expiredVerification']
      )
      expect(verification.faculty_status_for_step).to eq(User::SHEERID_EXPIRED)
    end

    it 'maps any other error to sheerid_error' do
      verification = FactoryBot.build(
        :sheerid_verification, current_step: 'error', error_ids: ['verificationLimitExceeded']
      )
      expect(verification.faculty_status_for_step).to eq(User::SHEERID_ERROR)
    end

    it 'maps expiredVerification with another error id to sheerid_error, not sheerid_expired' do
      verification = FactoryBot.build(
        :sheerid_verification,
        current_step: 'error',
        error_ids: ['expiredVerification', 'verificationLimitExceeded']
      )
      expect(verification.faculty_status_for_step).to eq(User::SHEERID_ERROR)
    end

    it 'maps an error step with no error ids to sheerid_error' do
      verification = FactoryBot.build(:sheerid_verification, current_step: 'error', error_ids: [])
      expect(verification.faculty_status_for_step).to eq(User::SHEERID_ERROR)
    end
  end

  describe '#expired?' do
    it 'is true only for an error step whose sole error id is expiredVerification' do
      expired = FactoryBot.build(
        :sheerid_verification, current_step: 'error', error_ids: ['expiredVerification']
      )
      other_error = FactoryBot.build(
        :sheerid_verification, current_step: 'error', error_ids: ['verificationLimitExceeded']
      )
      success = FactoryBot.build(:sheerid_verification, current_step: 'success')

      expect(expired.expired?).to be(true)
      expect(other_error.expired?).to be(false)
      expect(success.expired?).to be(false)
    end
  end

  describe '#error?' do
    it 'is true for any error step regardless of error id' do
      expect(FactoryBot.build(:sheerid_verification, current_step: 'error').error?).to be(true)
      expect(FactoryBot.build(:sheerid_verification, current_step: 'success').error?).to be(false)
    end
  end

  describe '.record_webhook!' do
    let(:details) do
      SheeridAPI::Response.new(
        'lastResponse' => {
          'currentStep' => 'success',
          'errorIds' => [],
          'rejectionReasons' => [],
          'segment' => 'teacher',
        },
        'personInfo' => {
          'firstName' => 'Jamie',
          'lastName' => 'Rivera',
          'email' => 'jamie@example.com',
          'organization' => { 'name' => 'Rice University' },
        }
      )
    end

    it 'creates a row on first delivery, stamping the webhook bookkeeping columns' do
      verification = described_class.record_webhook!(details, verification_id: 'vid-1')

      expect(verification).to be_persisted
      expect(verification.current_step).to eq('success')
      expect(verification.email).to eq('jamie@example.com')
      expect(verification.first_name).to eq('Jamie')
      expect(verification.last_name).to eq('Rivera')
      expect(verification.organization_name).to eq('Rice University')
      expect(verification.error_ids).to eq([])
      expect(verification.rejection_reasons).to eq([])
      expect(verification.segment).to eq('teacher')
      expect(verification.last_response).to eq(details.raw)
      expect(verification.webhook_count).to eq(1)
      expect(verification.webhook_received_at).to be_present
    end

    it 'upserts by verification_id and increments webhook_count on a later delivery' do
      described_class.record_webhook!(details, verification_id: 'vid-1')

      later_details = SheeridAPI::Response.new(
        'lastResponse' => { 'currentStep' => 'docUpload', 'errorIds' => [] },
        'personInfo' => nil
      )
      verification = described_class.record_webhook!(later_details, verification_id: 'vid-1')

      expect(described_class.where(verification_id: 'vid-1').count).to eq(1)
      expect(verification.current_step).to eq('docUpload')
      expect(verification.webhook_count).to eq(2)
    end

    it 'recovers when a concurrent delivery creates the row first' do
      existing = described_class.create!(verification_id: 'vid-race', current_step: 'success')
      allow(described_class).to receive(:find_or_create_by!)
        .and_raise(ActiveRecord::RecordNotUnique.new('duplicate key'))

      verification = described_class.record_webhook!(details, verification_id: 'vid-race')

      expect(verification.id).to eq(existing.id)
      expect(verification.webhook_count).to eq(1)
      expect(described_class.where(verification_id: 'vid-race').count).to eq(1)
    end
  end
end
