ActionController::Base.class_exec do
  # TODO: add a descriptive comment and document this magic in the readme
  include UserSessionManagement
  include ApplicationHelper
  include OSU::OsuHelper
  include LocaleSelector
  include RequireRecentSignin

  include AuthenticateMethods

  include ContractsNotRequired
  helper_method :contracts_not_required, :sso_cookies

  helper OSU::OsuHelper, ApplicationHelper, UserSessionManagement

  before_action :save_redirect

  fine_print_require :general_terms_of_use, :privacy_policy, unless: :disable_fine_print

    # TODO # BRYAN - REMOVE THIS. ADDED TEMPORARILY.
  def params
    request.parameters.with_indifferent_access
  end

  def sso_cookies
    request.sso_cookie_jar
  end

  def security_log(event_type, event_data = {})
    user = event_data[:user]

    if respond_to?(:current_api_user)
      api_user = current_api_user
      user ||= api_user.human_user
      application = api_user.application
    else
      user ||= current_user
      application = nil
    end

    SecurityLog.create!(
      user: user.try(:is_anonymous?) ? nil : user,
      application: application,
      remote_ip: request.remote_ip,
      event_type: event_type,
      event_data: event_data
    )
  end

  def save_redirect
    return true if request.format != :html || request.options?

    url = params["r"]

    return true if url.blank? || !Host.trusted?(url)

    store_url(url: url)
  end

  def disable_fine_print
    request.options? ||
    contracts_not_required ||
    current_user.is_anonymous?
  end
end
