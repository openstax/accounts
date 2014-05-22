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
    msg = CreateMessage.call(app, params[:to], params[:subject],
                             params[:body], params).outputs[:message]
    msg.deliver
    respond_with msg
  end

end