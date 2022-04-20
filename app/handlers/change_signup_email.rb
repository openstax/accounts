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
    email_param = change_signup_email_params.email.squish!

    if LookupUsers.by_verified_email(email_param).first
      fatal_error(
        code: :email_taken,
        message: I18n.t(:'login_signup_form.email_address_taken'),
        offending_inputs: :email
      )
    end

    @email_address = EmailAddress.where(user_id: options[:user].id).first
    @email_address.value = email_param
    @email_address.reset_confirmation_pin_code
    @email_address.save
    transfer_errors_from(@email_address, { scope: :email }, :fail_if_errors)

    send_confirmation_email
  end

  private ###################

  def send_confirmation_email
    NewflowMailer.signup_email_confirmation(email_address: @email_address).deliver_later
  end
end
