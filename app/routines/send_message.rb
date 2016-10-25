# Sends a Message object
class SendMessage

  # This is already called from within the save transaction
  lev_routine transaction: :no_transaction

  protected

  def exec(msg)
    outputs[:mail] = ApiMailer.mail(
      msg.body.html,
      msg.body.text,
      from: msg.from_address,
      to: msg.to_addresses,
      cc: msg.cc_addresses,
      bcc: msg.bcc_addresses,
      subject: msg.subject_string,
    ).deliver_later
  end

end
