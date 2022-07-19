class SignInHelpMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  def multiple_accounts(email_address:, usernames:)
    @email_address = email_address
    @usernames = usernames

    mail to: email_address,
         subject: "Your OpenStax usernames"
  end

  def reset_password(user:, email_address:)
    @user = user

    raise "No valid login token" if user.login_token.nil? || user.login_token_expired?

    mail to: "\"#{user.full_name}\" <#{email_address}>",
         subject: "Reset your OpenStax password"
  end

  def add_password(user:, email_address:)
    @user = user

    raise "No valid login token" if user.login_token.nil? || user.login_token_expired?

    mail to: "\"#{user.full_name}\" <#{email_address}>",
         subject: "Add a password to your OpenStax account"
  end

  def create_password_email(user:, email:)
    @user = user
    mail to: email, subject: 'Set up a password for your OpenStax account'
  end

  def reset_password_email(user:, email_address:)
    @user = user

    raise "No valid login token" if user.login_token.nil? || user.login_token_expired?

    mail to: "\"#{user.full_name}\" <#{email_address}>",
         subject: "Reset your OpenStax password"
  end

end
