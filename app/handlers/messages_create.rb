# Creates and sends a Message
class MessagesCreate

  lev_handler

  uses_routine AddRecipientsToMessage, as: :add_recipients_to_message
  uses_routine SendMessage, as: :send_message

  protected

  def setup
    self.params = ActionController::Parameters.new(params)
    params[:subject_prefix] ||= caller.application.email_subject_prefix
  end

  def authorized?
    OSU::AccessPolicy.action_allowed?(:create, caller, Message)
  end

  def handle
    fatal_error(code: :invalid_params, message: 'Invalid params') \
      unless params[:to].is_a?(Hash) && !params[:to].empty? &&
             params[:subject].is_a?(String) &&
             params[:body].is_a?(Hash) && !params[:body].empty?

    msg = Message.new(msg_params)
    msg.application = caller.application

    outputs[:message] = msg

    run(:add_recipients_to_message, msg, :to, dest_params(:to))
    run(:add_recipients_to_message, msg, :cc, dest_params(:cc)) if params[:cc]
    run(:add_recipients_to_message, msg, :bcc, dest_params(:bcc)) if params[:bcc]

    msg.body = MessageBody.new(body_params)

    # Save the message
    msg.save

    # Abort the routine if the message didn't save
    transfer_errors_from(msg, {type: :verbatim}, true)

    # Send the message or rollback the transaction if it wasn't sent
    run(:send_message, msg)
  end

  def msg_params
    params.require(:subject)
    params.permit(:user_id, :send_externally_now, :subject, :subject_prefix)
  end

  def dest_params(type)
    params.require(type).permit(literals: [], user_ids: [], group_ids: [])
  end

  def body_params
    params.require(:body).permit(:html, :text, :short_text)
  end

end
