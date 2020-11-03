ActionController::Base.class_exec do
  # TODO: add a descriptive comment and document this magic in the readme
  include UserSessionManagement
  include ApplicationHelper
  include OSU::OsuHelper
  include HttpAcceptLanguage::AutoLocale
  include RequireRecentSignin

  include AuthenticateMethods

  include ContractsNotRequired
  helper_method :contracts_not_required

  helper OSU::OsuHelper, ApplicationHelper, UserSessionManagement

  prepend_before_action :set_device_id
  before_action :save_redirect
  before_action :set_locale
  before_action :complete_signup_profile

  fine_print_require :general_terms_of_use, :privacy_policy, unless: :disable_fine_print

  UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/

  protected

  def complete_signup_profile
    return true if request.format != :html || request.options?
    redirect_to '/signup/profile' if current_user.is_needs_profile?
    # TODO: uncomment this line after fixing openstax_path_prefixer
    # redirect_to main_app.signup_profile_path if current_user.is_needs_profile?
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

    url = params[:r]

    return true if url.blank? || !Host.trusted?(url)

    store_url(url: url)
  end

  def disable_fine_print
    api_call? ||
    current_user.is_anonymous? ||
    request.options? ||
    contracts_not_required
  end

  def set_locale
    I18n.locale = http_accept_language.compatible_language_from(I18n.available_locales)
  end

  def set_device_id
    cookies.delete(:oxdid) if cookies[:oxdid] && !(cookies[:oxdid] =~ UUID_REGEX)

    if cookies[:oxdid].nil?
      cookies[:oxdid] = {
        value: SecureRandom.uuid,
        expires: 20.years.from_now,
        domain: :all,
        secure: Rails.env.production?
      }
    end
  end

  def get_device_id
    cookies[:oxdid]
  end
end
