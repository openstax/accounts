# Replacement for SessionsCreate handler.
# Handles the omniauth callback.
#
class NewflowSocialCallback
  include Rails.application.routes.url_helpers

  lev_handler

  protected #######################

  def authorized?
    true
  end

  def setup
    @came_from = URI.parse(request.env['omniauth.origin']).path
    @data = OmniauthData.new(request.env['omniauth.auth']) \
                        rescue fatal_error(code: :invalid_omniauth_data)
  end

  def handle
    # TODO: might want to undo the following line when we deploy to production
    social_provider = @data.provider == 'facebooknewflow' ? 'facebook' : @data.provider

    if logging_in?
      authentication = Authentication.find_by(
        provider: social_provider, uid: @data.uid.to_s
      )
      outputs[:user] = authentication.user
    outputs[:user] = authentication.user
    end
  end

  private #######################

  def logging_in?
    @came_from == newflow_login_path
  end

  def authentication
    # We don't use fatal_errors in this handler (we could, but we don't), so just build
    # don't create an authentication here because we don't want to leave orphaned
    # records lying around if we return a error-ish status
    outputs[:authentication] ||= Authentication.find_or_initialize_by(
                                                    provider: @data.provider, uid: @data.uid.to_s)
  end
end
