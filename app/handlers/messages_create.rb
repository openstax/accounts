# Creates and sends a Message
class MessagesCreate

  lev_handler

  uses_routine AddRecipientsToMessage, as: :add_recipients_to_message
  uses_routine SendMessage, as: :send_message

  protected

  def authorized?
    OSU::AccessPolicy.action_allowed?(:create, caller, Message)
  end

  def handle
    fatal_error(code: :invalid_params, message: 'Invalid params') \
      unless params[:to].is_a?(Hash) && !params[:to].empty? && \
        params[:subject].is_a?(String) && params[:body].is_a?(Hash) && \
        !params[:body].empty?

    app = caller.application
    params[:subject_prefix] ||= app.email_subject_prefix

    msg = Message.new(params.slice(:user_id, :send_externally_now, :subject, :subject_prefix))
    msg.application = app

    outputs[:message] = msg

    run(:add_recipients_to_message, msg, :to,
      params[:to].slice(:literals, :user_ids, :group_ids))
    run(:add_recipients_to_message, msg, :cc,
      params[:cc].slice(:literals, :user_ids, :group_ids)) if params[:cc]
    run(:add_recipients_to_message, msg, :bcc,
      params[:bcc].slice(:literals, :user_ids, :group_ids)) if params[:bcc]

    msg.body = MessageBody.new(params[:body].slice(:html, :text, :short_text))

    # Save the message
    msg.save

    # Abort the routine if the message didn't save
    transfer_errors_from(msg, {type: :verbatim}, true)

    # Send the message or rollback the transaction if it wasn't sent
    run(:send_message, msg)
  end

end
