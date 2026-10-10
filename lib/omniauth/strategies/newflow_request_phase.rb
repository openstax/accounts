# OmniAuth 1.x saves the `origin` param as session['omniauth.origin'], or failing
# that the whole Referer URL. We only ever read the param (`origin=login_form`,
# see OauthCallback::LOGIN_FORM_IS_ORIGIN), never the Referer. On
# /external_user_credentials/new the Referer carries the user's JWE access token
# in `?token=`, which on its own pushed the cookie session past 4KB and raised
# ActionDispatch::Cookies::CookieOverflow (Sentry ACCOUNTS-49R).
# The session cookie lasts 20 years, so this also drops one left by an earlier,
# abandoned attempt.
module NewflowRequestPhase
  def request_phase
    session.delete('omniauth.origin') unless request.params[options.origin_param]
    super
  end
end
