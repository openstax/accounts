module Newflow
  class SocialLoginFailedSetupPassword
    lev_handler

    protected #################

    def authorized?
      true
    end

    def handle
      # TODO: rate-limit this
      user = User.new(state: 'activated')
      user.refresh_login_token
      user.save
      transfer_errors_from(user, { type: :verbatim }, :fail_if_errors)
      email = EmailAddress.new(value: options[:email])

      email.update_attributes(user: user)
      transfer_errors_from(email, { type: :verbatim }, :fail_if_errors)

      NewflowMailer.newflow_setup_password(user: email.user, email: options[:email]).deliver_later
    end
  end
end
