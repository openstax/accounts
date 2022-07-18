class ConfirmEmailAddress
  lev_routine

  protected

  def exec(email_address)

    email_address.verified = true
    email_address.save

    transfer_errors_from(email_address, { type: :verbatim }, true)
  end
end
