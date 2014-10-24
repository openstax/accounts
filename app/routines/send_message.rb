# Sends a Message object
class SendMessage

  # This is already called from within the save transaction
  lev_routine transaction: :no_transaction

  protected

  def exec(msg)
    fatal_error(code: :not_sent, message: 'Message could not be sent') \
      unless Mail.deliver do
      from msg.from_address
      to msg.to_addresses
      cc msg.cc_addresses
      bcc msg.bcc_addresses
      subject msg.subject_string

      html_part do
        content_type 'text/html; charset=UTF-8'
        body msg.body.html
      end

      text_part do
        body msg.body.text
      end
    end
  end

end
