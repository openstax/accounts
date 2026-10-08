class RequestAccountDeletion

  lev_handler

  TOKEN_EXPIRATION = 1.day

  protected

  def authorized?
    !caller.is_anonymous?
  end

  def handle
    user = caller

    user.refresh_account_deletion_token(expiration_period: TOKEN_EXPIRATION)
    user.save!
    transfer_errors_from(user, { type: :verbatim }, true)

    email_addresses = user.email_addresses.verified.map(&:value)

    fatal_error(code: :no_verified_email) if email_addresses.empty?

    email_addresses.each do |email_address|
      NewflowMailer.account_deletion_confirmation(
        user: user,
        email_address: email_address
      ).deliver_later
    end

    outputs.user = user
  end
end
