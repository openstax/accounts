# If a user with the given email address is found, we send (to each of their verified
# email addresses) an email to reset their password.
# Otherwise, for security reasons, it returns early with no errors.
class ResetPasswordForm
  lev_handler

  LOGIN_TOKEN_EXPIRATION = 2.days

  paramify :reset_password_form do
    attribute :email
    validates :email, presence: true
  end

  protected #################

  def authorized?
    true
  end

  def handle
    user = LookupUsers.by_verified_email(reset_password_form_params.email).first
    outputs.user = user

    return unless user.present?

    user.refresh_login_token(expiration_period: LOGIN_TOKEN_EXPIRATION)
    user.save!

    email_addresses = user.email_addresses.verified.map(&:value)

    email_addresses.each do |email_address|
      SignInHelpMailer.send(
        :reset_password,
        user: user,
        email_address: email_address
      ).deliver_later
    end
  end
end
