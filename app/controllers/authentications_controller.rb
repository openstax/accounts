class AuthenticationsController < ApplicationController

  include RequireRecentSignin

  before_filter :reauthenticate_user_if_signin_is_too_old!

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
        render status: :ok,
               text: (I18n.t :"controllers.authentications.authentication_removed",
                             authentication: params[:provider].titleize)
      end,
      failure: lambda do
        render status: 422, text: @handler_result.errors.map(&:message).to_sentence
      end
    )
  end

  # This wrapper of the oauth route exists to do reauth before adding
  def add
    redirect_to "/auth/#{params[:provider]}?add=true"
  end

end
