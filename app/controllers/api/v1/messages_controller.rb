class Api::V1::MessagesController < Api::V1::ApiController
  include Lev::HandleWith

  resource_description do
    api_versions "v1"
    short_description 'Sends messages to users of Accounts.'
    description <<-EOS
      All actions in this controller require an Oauth token
      obtained through the Client Credentials flow.
      Only selected applications can currently access this API.

      Messages belong to applications.
      They represent messages sent to Users through their ContactInfos.

      They have the following fields:
      send_externally_now, from, to, cc, bcc, subject, subject_prefix, body
      The body has the following fields:
      html, text, short_text

      Unlike other API endpoints, this one uses the encoded form format
      instead of the JSON format
    EOS
  end

  ###############################################################
  # create
  ###############################################################

  api :POST, '/messages', 'Creates and sends a new Message.'
  description <<-EOS
    Creates and sends a new Message to the given users.
    Can only be called by a selected application, using a token
    obtained via the Client Credentials Oauth flow.
    Returns a JSON representation of the sent message.

    #{json_schema(Api::V1::MessageRepresenter, include: [:writeable])}
  EOS
  def create
    handle_with(MessagesCreate,
                caller: current_api_user,
                params: message_params,
                success: lambda {
                           respond_with @handler_result.outputs[:message],
                                        status: :created, location: nil
                         },
                failure: lambda {
                  render json: {errors: @handler_result.errors},
                  status: :unprocessable_entity
                })
  end

  private

  def message_params
    # too nested for rails to handle otherwise, yet okay because we `slice`
    params.permit!.to_h
  end
end
