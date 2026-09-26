require 'rails_helper'

describe Newflow::EducatorSignup::SheeridWebhook, type: :routine do
  let(:user)           { FactoryBot.create(:user, role: User::INSTRUCTOR_ROLE) }
  let!(:email_address) { FactoryBot.create(:email_address, :verified, user: user) }
  let!(:school) do
    FactoryBot.create(
      :school,
      salesforce_id: '0017h00000doU3RAAU',
      name: 'University of Arkansas, Monticello',
      city: 'Monticello',
      state: 'AR',
      sheerid_school_name: 'University of Arkansas, Monticello (Monticello, AR)'
    )
  end
  let(:verification_id) { Faker::Internet.uuid }

  # Builds a SheeridAPI::Response the way SheerID's actual verification-details
  # payload shapes it: personInfo is entirely absent (JSON null) for error and
  # collectTeacherPersonalInfo steps.
  def response_for(
    current_step:, error_ids: [], rejection_reasons: [], segment: 'teacher', with_person_info: true
  )
    body = {
      'lastResponse' => {
        'currentStep' => current_step,
        'errorIds' => error_ids,
        'rejectionReasons' => rejection_reasons,
        'segment' => segment,
      },
      'personInfo' => with_person_info ? {
        'firstName' => user.first_name,
        'lastName' => user.last_name,
        'email' => email_address.value,
        'organization' => { 'name' => school.sheerid_school_name },
      } : nil,
    }
    SheeridAPI::Response.new(body)
  end

  def stub_details(id, details)
    allow(SheeridAPI).to receive(:get_verification_details).with(id).and_return(details)
  end

  def call_webhook(id = verification_id)
    described_class.call(params: { 'verificationId' => id })
  end

  before do
    allow(Sentry).to receive(:capture_message)
    allow(Newflow::CreateOrUpdateSalesforceLead).to receive(:perform_later)
  end

  context 'user who has since switched to a student account' do
    before do
      user.update!(role: User::STUDENT_ROLE, faculty_status: User::REJECTED_FACULTY)
      stub_details(verification_id, response_for(current_step: 'success'))
    end

    it 'ignores the verification instead of re-attaching educator fields' do
      call_webhook

      user.reload
      expect(user.role).to eq('student')
      expect(user.faculty_status).to eq(User::REJECTED_FACULTY)
      expect(user.sheerid_verification_id).to be_nil
      expect(
        SecurityLog.where(event_type: :sheerid_webhook_ignored_after_role_switch).count
      ).to eq(1)
    end

    it 'does not push a lead off the educator path' do
      call_webhook

      expect(Newflow::CreateOrUpdateSalesforceLead).not_to have_received(:perform_later)
    end
  end

  describe 'the faculty_status_for_step mapping, applied end to end' do
    it 'success -> confirmed_faculty' do
      stub_details(verification_id, response_for(current_step: 'success'))

      call_webhook

      expect(user.reload.faculty_status).to eq(User::CONFIRMED_FACULTY)
      expect(user.school).to eq(school)
      expect(SecurityLog.where(event_type: :fv_success_by_sheerid, user: user).count).to eq(1)

      verification = SheeridVerification.find_by(verification_id: verification_id)
      expect(verification.current_step).to eq('success')

      log = SecurityLog.find_by(event_type: :fv_success_by_sheerid, user: user)
      expect(log.event_data).to include(
        'verification_id' => verification_id, 'current_step' => 'success', 'error_ids' => []
      )
      expect(Sentry).not_to have_received(:capture_message)
    end

    it 'rejected -> rejected_by_sheerid' do
      stub_details(
        verification_id,
        response_for(current_step: 'rejected', rejection_reasons: ['nameMismatch'])
      )

      call_webhook

      expect(user.reload.faculty_status).to eq(User::REJECTED_BY_SHEERID)
      expect(SecurityLog.where(event_type: :fv_reject_by_sheerid, user: user).count).to eq(1)

      verification = SheeridVerification.find_by(verification_id: verification_id)
      expect(verification.rejection_reasons).to eq(['nameMismatch'])
      expect(Sentry).not_to have_received(:capture_message)
    end

    it 'docUpload -> pending_sheerid' do
      stub_details(verification_id, response_for(current_step: 'docUpload'))

      call_webhook

      expect(user.reload.faculty_status).to eq(User::PENDING_SHEERID)
      expect(SecurityLog.where(event_type: :sheerid_webhook_pending, user: user).count).to eq(1)
      expect(Sentry).not_to have_received(:capture_message)
    end

    it 'collectTeacherPersonalInfo -> pending_sheerid, now persists a row (used to return early)' do
      user.update!(sheerid_verification_id: verification_id)
      details = response_for(current_step: 'collectTeacherPersonalInfo', with_person_info: false)
      stub_details(verification_id, details)

      expect { call_webhook }.to change(SheeridVerification, :count).by(1)

      expect(user.reload.faculty_status).to eq(User::PENDING_SHEERID)
      expect(SecurityLog.where(event_type: :sheerid_webhook_pending, user: user).count).to eq(1)
      expect(Sentry).not_to have_received(:capture_message)
    end

    it 'resolves the user by sheerid_verification_id when the payload carries no email' do
      user.update!(sheerid_verification_id: verification_id)
      details = response_for(current_step: 'docUpload', with_person_info: false)
      stub_details(verification_id, details)

      call_webhook

      expect(user.reload.faculty_status).to eq(User::PENDING_SHEERID)
    end
  end

  context 'when SheerID reports an error step, with a user resolved by sheerid_verification_id' do
    before { user.update!(sheerid_verification_id: verification_id) }

    it 'maps verificationLimitExceeded to sheerid_error and reports it to Sentry as a warning' do
      details = response_for(
        current_step: 'error', error_ids: ['verificationLimitExceeded'], with_person_info: false
      )
      stub_details(verification_id, details)

      call_webhook

      expect(user.reload.faculty_status).to eq(User::SHEERID_ERROR)
      expect(SecurityLog.where(event_type: :sheerid_webhook_error, user: user).count).to eq(1)
      expect(Sentry).to have_received(:capture_message).with(
        '[SheerID Webhook] error step received',
        level: :warning,
        extra: {
          user_id: user.id, verification_id: verification_id,
          error_ids: ['verificationLimitExceeded']
        }
      )
    end

    it 'maps expiredVerification to sheerid_expired, still reporting it since a user is attached' do
      details = response_for(
        current_step: 'error', error_ids: ['expiredVerification'], with_person_info: false
      )
      stub_details(verification_id, details)

      call_webhook

      expect(user.reload.faculty_status).to eq(User::SHEERID_EXPIRED)
      expect(SecurityLog.where(event_type: :sheerid_webhook_expired, user: user).count).to eq(1)
      expect(Sentry).to have_received(:capture_message).with(
        '[SheerID Webhook] error step received',
        level: :warning,
        extra: {
          user_id: user.id, verification_id: verification_id, error_ids: ['expiredVerification']
        }
      )
    end

    it 'refuses to downgrade a confirmed_faculty user, but logs the refusal and reports it' do
      user.update!(faculty_status: User::CONFIRMED_FACULTY)
      details = response_for(
        current_step: 'error', error_ids: ['expiredVerification'], with_person_info: false
      )
      stub_details(verification_id, details)

      call_webhook

      expect(user.reload.faculty_status).to eq(User::CONFIRMED_FACULTY)
      expect(
        SecurityLog.where(event_type: :faculty_status_downgrade_refused, user: user).count
      ).to eq(1)
      expect(SecurityLog.where(event_type: :sheerid_webhook_expired, user: user).count).to eq(1)
      expect(Sentry).to have_received(:capture_message)
        .with('[SheerID Webhook] error step received', anything)
    end
  end

  context 'when SheerID reports an error step and no user can be resolved' do
    it 'stays quiet for an expired verification, which is abandonment, not an error' do
      details = response_for(
        current_step: 'error', error_ids: ['expiredVerification'], with_person_info: false
      )
      stub_details(verification_id, details)

      call_webhook

      expect(Sentry).not_to have_received(:capture_message)
    end

    it 'stays quiet for any other error step too, once no user is resolved' do
      details = response_for(
        current_step: 'error', error_ids: ['verificationLimitExceeded'], with_person_info: false
      )
      stub_details(verification_id, details)

      call_webhook

      expect(Sentry).not_to have_received(:capture_message)
    end

    it 'still persists the verification row for an expired webhook' do
      details = response_for(
        current_step: 'error', error_ids: ['expiredVerification'], with_person_info: false
      )
      stub_details(verification_id, details)

      expect { call_webhook }.to change(SheeridVerification, :count).by(1)

      verification = SheeridVerification.find_by(verification_id: verification_id)
      expect(verification.current_step).to eq('error')
      expect(verification.error_ids).to eq(['expiredVerification'])
    end

    it 'logs nothing at all for an expired webhook with no user attached' do
      details = response_for(
        current_step: 'error', error_ids: ['expiredVerification'], with_person_info: false
      )
      stub_details(verification_id, details)

      expect { call_webhook }.not_to change(SecurityLog, :count)
    end

    it 'does not push a Salesforce lead' do
      details = response_for(
        current_step: 'error', error_ids: ['expiredVerification'], with_person_info: false
      )
      stub_details(verification_id, details)

      call_webhook

      expect(Newflow::CreateOrUpdateSalesforceLead).not_to have_received(:perform_later)
    end
  end

  context 'when SheerID cannot be reached' do
    it 'fatal_errors instead of processing a NullResponse' do
      stub_details(verification_id, SheeridAPI::NullResponse.instance)

      result = call_webhook

      expect(result.errors.first.code).to eq(:sheerid_api_call_failed)
    end
  end
end
