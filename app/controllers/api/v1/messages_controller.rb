class Api::V1::MessagesController < OpenStax::Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'Sends messages to users of Accounts.'
    description <<-EOS
      All actions in this controller require an Oauth token
      obtained through the Client Credentials flow.
      Only trusted applications can currently access this API.

      Messages belong to applications.
      They represent messages sent to Users through their ContactInfos.

      They have the following fields:
      send_externally_now, from, to, cc, bcc, subject, subject_prefix, body
      The body has the following fields:
      html, text, short_text
    EOS
  end

  ###############################################################
  # index
  ###############################################################

  # api :GET, '/messages', 'Gets messages matching the search criteria.'
  # description <<-EOS
  #   Accepts a query string along with options and returns a JSON
  # representation of the matching Messages. The schema for the returned JSON
  # result is shown below.
  #
  #   {json_schema(Api::V1::MessageSearchRepresenter, include: :readable)}
  # EOS
  # def index
  # end

  ###############################################################
  # create
  ###############################################################

  api :POST, '/messages', 'Creates and sends a new Message.'
  description <<-EOS
    Creates and sends a new Message to the given users.
    Can only be called by a trusted application, using a token
    obtained via the Client Credentials Oauth flow.
    Returns a JSON representation of the sent message.

    #{json_schema(Api::V1::MessageRepresenter, include: [:writeable])}
  EOS
  def create
    app = current_application

    params[:subject_prefix] ||= app.email_subject_prefix

    msg = Message.new(params.slice(:user_id, :send_externally_now, :subject, :subject_prefix))
    msg.application = app
    msg.add_recipients(:to, params[:to].slice(:literals, :user_ids, :group_ids))
    msg.add_recipients(:cc, params[:cc].slice(:literals, :user_ids,
                                              :group_ids)) if params[:cc]
    msg.add_recipients(:bcc, params[:bcc].slice(:literals, :user_ids,
                                                :group_ids)) if params[:bcc]
    msg.body = MessageBody.new(params[:body].slice(:html, :text, :short_text))

    OSU::AccessPolicy.require_action_allowed!(:create, current_api_user, msg)
    msg.save!

    respond_with msg
  end

end