class AuthenticationsController < ApplicationController

  include RequireRecentSignin

  # Remove authentication method (OAuth provider) from account
  def destroy
    return reauthenticate_user! if user_signin_is_too_old?

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
