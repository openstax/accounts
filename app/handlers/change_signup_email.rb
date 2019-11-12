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
    email = change_signup_email_params.email

    if LookupUsers.by_verified_email(email).first
      fatal_error(code: :email_taken, message: 'Email address taken', offending_inputs: :email)
    end

    pas = options[:pre_auth_state]
    user = pas.user

    fatal_error(email: :is_not_the_only_one) if user.email_addresses.count > 1

    new_email_address = EmailAddress.create(value: email, user_id: user.id)
    transfer_errors_from(new_email_address, { scope: :email }, :fail_if_errors)

    # Destroy the previous email, although we could keep it since it's not verified.
    user.email_addresses.first.destroy

    # reset the PAS's confirmation pin/code
    pas.send :initialize_tokens
    pas.contact_info_value = email
    pas.save
    transfer_errors_from(pas, { scope: :email }, :fail_if_errors)
    # transer the PAS's confirmation pin/code over to the email address
    new_email_address.confirmation_pin = pas.confirmation_pin
    new_email_address.confirmation_code = pas.confirmation_code
    new_email_address.save
    transfer_errors_from(new_email_address, { scope: :email }, :fail_if_errors)

    send_confirmation_email(pas)

    outputs.pre_auth_state = pas
  end

  private ###################

  def send_confirmation_email(pre_auth_state)
    SignupConfirmationMailer.instructions(
      pre_auth_state: pre_auth_state
    ).deliver_later
  end
end
