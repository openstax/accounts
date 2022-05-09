ActionController::Base.class_exec do
  # We need some of the methods added here in all controllers
  # For example, `current_user` is used in the layout so it needs to exist everywhere
  # OpenStax Account's controllers all inherit from ApplicationController,
  # but gem controllers like FinePrint's and Blazer's do not, so adding them there wouldn't work
  # However, all controllers inherit from ActionController::Base,
  # so adding these methods to ActionController::Base directly here should work
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

  fine_print_require :general_terms_of_use, :privacy_policy, unless: :disable_fine_print

  protected

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
      event_data: event_data.except!(:user)
    )
  end

  def save_redirect
    return true if request.format != :html || request.options?

    url = params[:r]
    return true if url.blank? || !Host.trusted?(url)
    store_url(url: url)
  end

  def disable_fine_print
    user = respond_to?(:current_human_user) ? current_human_user : current_user
    api_call? ||
      user&.is_anonymous? ||
      request.options? ||
      contracts_not_required
  end

  def set_locale
    I18n.locale = http_accept_language.compatible_language_from(I18n.available_locales)
  end

  def set_device_id
    cookies.delete(:oxdid) if device_id_invalid?

    cookies[:oxdid] ||= {
      value: SecureRandom.uuid,
      expires: 20.years.from_now,
      domain: :all,
      secure: Rails.env.production?
    }
  end

  def get_device_id
    cookies[:oxdid]
  end

  def device_id_invalid?
    cookies[:oxdid] && !(cookies[:oxdid] =~ UUID_REGEX)
  end
end
