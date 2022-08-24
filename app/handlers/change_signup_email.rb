class ChangeSignupEmail
  lev_handler

  paramify :change_signup_email do
    attribute :email
    attribute :old_email
    validates :email, presence: true
  end

  protected #################

  def authorized?
    true
  end

  def handle
    new_email = change_signup_email_params.email.squish!

    if LookupUsers.by_verified_email(new_email).first
      fatal_error(
        code: :email_taken,
        message: I18n.t(:"login_signup_form.email_address_taken"),
        offending_inputs: :email
      )
    end

    @email_address = EmailAddress.where(value: change_signup_email_params.old_email).first
    @email_address.value = new_email
    @email_address.reset_confirmation_pin_code
    @email_address.save

    outputs.email_address = @email_address

    transfer_errors_from(@email_address, { scope: :email }, :fail_if_errors)

    send_confirmation_email
  end

  private ###################

  def send_confirmation_email
    ConfirmationMailer.signup_email_confirmation(email_address: @email_address).deliver_later
  end
end
