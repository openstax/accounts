class SendConfirmationEmail

  include Lev::Routine

protected

  def exec(email_address)
    return if email_address.verified
    fatal_error(code: :no_confirmation_code, data: email_address) if email_address.confirmation_code.blank?

    ConfirmationMailer.instructions(email_address).deliver

    email_address.confirmation_sent_at = Time.now
    email_address.save
  end

end
