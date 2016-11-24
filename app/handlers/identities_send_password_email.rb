class IdentitiesSendPasswordEmail

  lev_handler

  protected

  def authorized?
    true
  end

  def handle
    fatal_error(code: :user_missing) if user.nil?

    user.reset_login_token
    user.save
    transfer_errors_from(user, {type: :verbatim}, true)

    email_addresses = user.email_addresses.verified.map(&:value)

    email_addresses.each do |email_address|
      SignInHelpMailer.send(
        mailer_method,
        user: options[:user],
        email_address: email_address
      ).deliver_later
    end
  end

  def user
    options[:user]
  end

  def mailer_method
    case options[:kind]
    when :add
      :add_password
    when :reset
      :reset_password
    else
      raise IllegalArgument
    end
  end

end
