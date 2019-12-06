module Newflow
  # Handles log in form submission.
  # Tries to find a user by email (or username for legacy reasons),
  # then checks the password for the user.
  # If successful, outputs the user. Otherwise, fails and logs the error.
  class AuthenticateUser
    lev_handler

    paramify :login_form do
      attribute :email, type: String
      attribute :password, type: String

      validates :email, presence: true
      validates :password, presence: true
    end

    protected ###############

    def authorized?
      true
    end

    def handle
      outputs.email = login_form_params.email

      # We should be searching by email
      # but we'd like to continue to support users who only have a username.
      users = LookupUsers.by_email_or_username(login_form_params.email)

      if users.empty?
        fail_with_log!('cannot_find_user', :email)
      elsif users.size > 1
        fail_with_log!('multiple_users', :email) # should user really be nil? why not the email value?
      end

      user = users.first
      identity = Identity.authenticate({ user_id: user&.id }, login_form_params.password)
      fail_with_log!('incorrect_password', :password, user) unless identity.present?
      outputs.user = user
    end

    private #################

    def fail_with_log!(reason, input_field, user = nil)
      SecurityLog.create!(
        event_type: :sign_in_failed,
        event_data: { reason: reason },
        user: user,
        remote_ip: request.ip
      )

      fatal_error(
        code: reason.to_sym,
        offending_inputs: input_field,
        message: I18n.t("login_signup_form.#{reason}".to_sym)
      )
    end
  end
end
