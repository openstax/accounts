# Replacement for SessionsCreate handler.
# Handles the omniauth callback.
#
class NewflowSocialCallback
  lev_handler

  protected

  def authorized?
    true
  end

  def setup
    @data = OmniauthData.new(request.env['omniauth.auth']) \
                        rescue fatal_error(code: :invalid_omniauth_data)
  end

  def handle
    outputs[:user] = authentication.user
  end

#####################

  def authentication
    # We don't use fatal_errors in this handler (we could, but we don't), so just build
    # don't create an authentication here because we don't want to leave orphaned
    # records lying around if we return a error-ish status
    outputs[:authentication] ||= Authentication.find_or_initialize_by(
                                                    provider: @data.provider, uid: @data.uid.to_s)
  end
end
