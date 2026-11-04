module Newflow
  class ChangeSignupEmail
    lev_handler

    uses_routine SendSignupConfirmationEmail

    paramify :change_signup_email do
      attribute :email
      validates :email, presence: true
    end

    protected #################

    def authorized?
      true
    end

    def handle
      email_param = change_signup_email_params.email.squish!

      if EmailAddress.claimed?(email_param, excluding_user_id: options[:user].id)
        fatal_error(
          code: :email_taken,
          message: I18n.t(:"login_signup_form.email_address_taken"),
          offending_inputs: :email
        )
      end

      # Edit the address the PIN form is actually confirming, not whichever
      # address happens to sort first on the account.
      @email_address = options[:email_address] || EmailAddress.where(user_id: options[:user].id).first
      # Re-entering the same address is how people ask for the email again; a
      # new PIN there would make the first email's PIN wrong when it arrives.
      @email_address.reset_confirmation_pin_code unless @email_address.value.casecmp?(email_param)
      @email_address.value = email_param
      @email_address.save
      transfer_errors_from(@email_address, { scope: :email }, :fail_if_errors)

      send_confirmation_email
    end

    private ###################

    def send_confirmation_email
      run(SendSignupConfirmationEmail, email_address: @email_address)
    end
  end
end
