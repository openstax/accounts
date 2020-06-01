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
      user_sheerid_info = details.fetch('personInfo')

      email = user_sheerid_info.fetch('email')
      outputs[:user] = user = User.find_by(sheerid_verification_id: verification_id)

      fatal_error(code: :email_mismatch) if email_mismatch?(email, user)

      user.update!(
        first_name: user_sheerid_info.fetch('firstName'),
        last_name: user_sheerid_info.fetch('lastName'),
        sheerid_reported_school: user_sheerid_info.fetch('organization').fetch('name'),
        faculty_status: (sheer_id_status == 'success' ? :confirmed_faculty : :pending_faculty),
      )
      create_security_log(user, details)
    end

    private #################

    # true if no user found with such email or if that email email address belongs to someone else
    def email_mismatch?(email, user)
      existing_email = EmailAddress.find_by(value: email)

      if !user.present? || !existing_email.present? || existing_email.user_id != user.id
        Raven.capture_message(
          'verification id and email mismatch',
          extra: {
            email: email, existing_email: existing_email,  user_id: user&.id
          }
        )
        return true
      else
        return false
      end
    end

    def create_security_log(user, data)
      SecurityLog.create!(
        event_type: :user_updated_using_sheerid_data,
        event_data: data,
        user: user
      )
    end
  end
end
