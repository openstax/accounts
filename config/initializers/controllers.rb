ActionController::Base.class_exec do

  use_openstax_exception_rescue

  protect_from_forgery

  layout 'application'

  include OSU::OsuHelper
  include ApplicationHelper
  include UserSessionManagement
  include LocaleSelector
  include RequireRecentSignin

  helper OSU::OsuHelper, ApplicationHelper, UserSessionManagement

  before_filter :save_redirect
  before_filter :authenticate_user!
  before_filter :complete_signup_profile
  before_filter :check_if_password_expired
  before_filter :set_locale

  fine_print_require :general_terms_of_use, :privacy_policy, unless: :disable_fine_print

  protected

  def security_log(event_type, event_data = {})
    if respond_to?(:current_api_user)
      api_user = current_api_user
      user = api_user.human_user
      application = api_user.application
    else
      user = current_user
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

  def disable_fine_print
    request.options? ||
    contracts_not_required(client_id: params[:client_id] || session[:client_id]) ||
    current_user.is_anonymous?
  end

  include ContractsNotRequired

  def complete_signup_profile
    return true if request.format != :html || request.options?
    redirect_to signup_profile_path if current_user.is_needs_profile?
  end

  def check_if_password_expired
    return true if request.format != :html || request.options?

    identity = current_user.identity
    return unless identity.try(:password_expired?)

    flash[:alert] = I18n.t :"controllers.identities.password_expired"
    redirect_to password_reset_path
  end

  def save_redirect
    return true if request.format != :html || request.options?

    url = params["r"]

    return true unless url.present?

    valid_hosts = Rails.application.secrets.valid_iframe_origins.map do |origin|
      URI.parse(origin).host
    end

    valid_hosts.unshift("127.0.0.1") if !Rails.env.production?

    uri = URI.parse(url)

    return true unless valid_hosts.any?{|valid_host| uri.host.ends_with?(valid_host)}

    store_url(url: url)
  end

end
