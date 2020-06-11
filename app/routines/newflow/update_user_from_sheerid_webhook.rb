module Newflow
  class UpdateUserFromSheeridWebhook
    lev_routine express_output: :user

    protected ###############

    def exec(verification_id:)
      status.set_job_name(self.class.name)
      status.set_job_args(verification_id: verification_id)

      details = SheeridAPI.get_verification_details(verification_id)

      last_response = details.fetch('lastResponse')
      sheer_id_status = last_response.fetch('currentStep')
      sheerid_person_info = details.fetch('personInfo')

      outputs.sheerid_email = sheerid_person_info.fetch('email')
      outputs.existing_email = EmailAddress.find_by(value: outputs.sheerid_email)
      outputs.user = user = User.find_by(sheerid_verification_id: verification_id)

      capture_mismatch_error! if email_mismatch?

      outputs.user.update!(
        first_name: sheerid_person_info.fetch('firstName'),
        last_name: sheerid_person_info.fetch('lastName'),
        sheerid_reported_school: sheerid_person_info.fetch('organization').fetch('name'),
        faculty_status: (sheer_id_status == 'success' ? :confirmed_faculty : :pending_faculty),
      )
      create_security_log(details)
    end

    private #################

    def capture_mismatch_error!
      error_message = 'verification id and email mismatch'

      Raven.capture_message(
        error_message,
        extra: {
          sheerid_email: outputs.sheerid_email,
          existing_email: outputs.existing_email,
          user_id: outputs.user&.id
        }
      )
      fatal_error(code: :email_mismatch, message: error_message)
    end

    def email_mismatch?
      outputs.user.blank? || outputs.existing_email.blank? || outputs.existing_email.user_id != outputs.user.id
    end

    def create_security_log(data)
      SecurityLog.create!(
        event_type: :user_updated_using_sheerid_data,
        event_data: data,
        user: outputs.user
      )
    end
  end
end
