module Newflow
  # Delete previous email, add new one to the user, update pre_auth_state's email value.
  class ChangeSignupEmail
    lev_handler

    paramify :change_signup_email do
      attribute :email
      validates :email, presence: true
    end

    protected #################

    def authorized?
      true
    end

    def handle
      email_param = change_signup_email_params.email

      if LookupUsers.by_verified_email(email_param).first
        fatal_error(code: :email_taken, message: 'Email address taken', offending_inputs: :email)
      end

      @email_address = EmailAddress.where(user_id: options[:user].id).first
      @email_address.value = email_param

      # reset confirmation pin and code
      @email_address.confirmation_pin = nil
      @email_address.confirmation_code = nil
      @email_address.set_confirmation_pin_code

      @email_address.save
      transfer_errors_from(@email_address, { scope: :email }, :fail_if_errors)

      send_confirmation_email
    end

    private ###################

    def send_confirmation_email
      NewflowMailer.signup_email_confirmation(email_address: @email_address).deliver_later
    end
  end
end
