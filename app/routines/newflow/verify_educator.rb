module Newflow
  # Verify their Educator status given their (SheerID) Verification ID
  # Expects a user to already exist with that SheerID Verification ID
  class VerifyEducator
    lev_routine active_job_enqueue_options: { queue: :educator_signup_queue }, use_jobba: true
    uses_routine UpsertSheeridVerification
    uses_routine UpdateSalesforceLead

    protected ###############

    def exec(verification_id:, user:)
      status.set_job_name(self.class.name)
      status.set_job_args(verification_id: verification_id.to_s, user: user.to_global_id.to_s)

      verification_record = fetch_verification(verification_id)
      transfer_errors_from(verification_record, {type: :verbatim}, :fail_if_errors)
      return if !verification_record.verified?

      # If the user is already faculty verified, nothing to do. If they're a student, don't faculty verify.
      return if user.confirmed_faculty? || user.student?

      email = EmailAddress.verified.find_by(value: verification_record.email)

      capture_mismatch_error!(verification_id, email, user) and return if email_mismatch?(user, email)

      if update_user(user, verification_record) && update_salesforce_lead_for(user)
        log_success(verification_id, user)
      else
        handle_error(verification_id, user)
      end
    end

    private #################

    def update_user(user, verification)
      Rails.logger.info("bryan_sheerid_verify #{self.class.name} #{user.inspect}")
      succeeded = user.update(
        first_name: verification.first_name,
        last_name: verification.last_name,
        sheerid_reported_school: verification.organization_name,
        faculty_status: verification.current_step_to_faculty_status,
        sheerid_verification_id: verification.verification_id
      )
      Rails.logger.info("bryan_sheerid_verify #{self.class.name} #{user.inspect}")
      succeeded
    end

    def fetch_verification(verification_id)
      @fetch_verification ||= run(UpsertSheeridVerification, verification_id: verification_id).outputs.verification
    end

    def update_salesforce_lead_for(user)
      run(UpdateSalesforceLead, user: user).outputs.lead.errors.none?
    end

    def email_mismatch?(user, email)
      user.blank? || email.blank? || email.user_id != user.id
    end

    def capture_mismatch_error!(verification_id, email, user)
      message = 'verification id and email mismatch'
      Rails.logger.warn("bryan_sheerid_verify. Email (#{email&.id}) mismatch! User (#{user&.id}) Verification (#{verification_id})")

      Raven.capture_message(
        message,
        extra: {
          verification_id: verification_id,
          email_id: email&.id,
          user_id: user&.id
        }
      )
      nonfatal_error(code: :email_mismatch, message: message)
    end

    def log_success(verification_id, user)
      lead_id = user.salesforce_lead_id
      Rails.logger.info("bryan_sheerid_verify #{self.class.name}: success for user (#{user.id}) with lead (#{lead_id})")

      SecurityLog.create!(
        user: user,
        event_type: :educator_verified_using_sheerid,
        event_data: { verification_id: verification_id, lead_id: lead_id }
      )
    end

    def handle_error(verification_id, user)
      message = "bryan_sheerid_verify #{self.class.name} error!; " \
        "User (#{user.id}) verification_id (#{verification_id}); User errors (#{user.errors.full_messages})"

        Rails.logger.warn(message)
      fatal_error(code: :error_updating_user, message: message)
    end
  end
end
