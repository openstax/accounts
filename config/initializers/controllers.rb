ActionController::Base.class_exec do
  # TODO: add a descriptive comment and document this magic in the readme
  include UserSessionManagement
  include ApplicationHelper
  include OSU::OsuHelper
  include LocaleSelector
  include RequireRecentSignin

  include ContractsNotRequired
  helper_method :contracts_not_required, :sso_cookies

  helper OSU::OsuHelper, ApplicationHelper, UserSessionManagement

  before_action :save_redirect

  def save_redirect
    return true if request.format != :html || request.options?

    url = params["r"]

    return true if url.blank? || !Host.trusted?(url)

    store_url(url: url)
  end
end
