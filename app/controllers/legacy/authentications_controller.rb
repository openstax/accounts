module Legacy
  class AuthenticationsController < ApplicationController
    before_action :reauthenticate_user_if_signin_is_too_old!

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
                plain: (I18n.t :"controllers.authentications.authentication_removed",
                              authentication: params[:provider].titleize)
        end,
        failure: lambda do
          render status: 422, plain: @handler_result.errors.map(&:message).to_sentence
        end
      )
    end

    # This wrapper of the oauth route exists to do reauth before adding.
    # omniauth 2.0 only accepts the request phase over POST (CVE-2015-9284), so we can't just
    # 302-redirect to /auth/:provider — a browser would follow that as a GET and be rejected.
    # Instead we render an auto-submitting POST form (with the Rails CSRF token) that starts the
    # request phase. `add=true` rides in the query string because omniauth captures request.GET
    # (not the POST body) into `omniauth.params`, which SessionsCreate reads to branch the flow.
    def add
      @provider = params[:provider]
    end
  end
end
