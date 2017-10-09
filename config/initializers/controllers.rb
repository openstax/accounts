ActionController::Base.class_exec do

  use_openstax_exception_rescue

  protect_from_forgery

  layout 'application'

  include OSU::OsuHelper
  include ApplicationHelper
  include UserSessionManagement
  include UseSignedParams
  include LocaleSelector
  include RequireRecentSignin

  include ContractsNotRequired
  helper_method :contracts_not_required

  helper OSU::OsuHelper, ApplicationHelper, UserSessionManagement

  prepend_before_filter :verify_signed_params

  before_filter :save_redirect
  before_filter :authenticate_user!
  before_filter :complete_signup_profile
  before_filter :check_if_password_expired
  before_filter :set_locale

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
      event_data: event_data
    )
  end

  def disable_fine_print
    request.options? ||
    contracts_not_required ||
    current_user.is_anonymous?
  end

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

    return true if url.blank?

    uri = URI.parse(url)

    return true if uri.host.blank?

    valid_host_regexes = Rails.application.secrets.valid_redirect_host_regexes.map do |regex_string|
      Regexp.new(regex_string)
    end

    return true if valid_host_regexes.none?{|regex| uri.host.match(regex)}

    store_url(url: url)
  end

  def return_url_specified_and_allowed?
    # This returns true iff `save_redirect` actually saved the URL
    params[:r] && params[:r] == stored_url
  end

  def verify_signed_params
    return true if params[:sp].nil?

    app = ::Doorkeeper::Application.find_by_uid(params[:client_id])

    if app.nil?
      Rails.logger.warn { "Unknown app for signed parameters" }
      head(:bad_request)
    elsif !OpenStax::Api::Params.signature_and_timestamp_valid?(params: params[:sp], secret: app.secret)
      Rails.logger.warn { "Invalid signature or timestamp for signed parameters" }
      head(:bad_request)
    end
  end

end
