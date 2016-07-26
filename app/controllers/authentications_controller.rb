class AuthenticationsController < ApplicationController

  # Add authentication method (OAuth provider) to account
  def create
  end

  # Remove authentication method (OAuth provider) from account
  def destroy
    handle_with(
      AuthenticationsDelete,
      success: lambda do
        authentication = @handler_result.outputs.authentication
        security_log :authentication_deleted,
                     authentication_id: authentication.id,
                     authentication_provider: authentication.provider,
                     authentication_uid: authentication.uid
        render status: :ok, text: "#{params[:provider].titleize} removed"
      end,
      failure: lambda do
        render status: 400, text: @handler_result.errors.map(&:message).to_sentence
      end
    )
  end

end
