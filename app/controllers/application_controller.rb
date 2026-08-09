class ApplicationController < ActionController::Base
  layout 'application'

  before_action :authenticate_user!
  before_action :complete_signup_profile
  before_action :check_if_password_expired
  before_action :set_sentry_user

  fine_print_require :general_terms_of_use, :privacy_policy, unless: :disable_fine_print

  def disable_fine_print
    request.options? ||
    contracts_not_required ||
    current_user.is_anonymous?
  end

  def check_if_admin
    return true if Rails.env.test?
    is_admin?
  end

  def check_if_password_expired
    return true if request.format != :html || request.options?

    identity = current_user.identity
    return unless identity.try(:password_expired?)

    flash[:alert] = I18n.t(:"controllers.identities.password_expired")
    redirect_to(password_reset_path)
  end

  def return_url_specified_and_allowed?
    # This returns true if `save_redirect` actually saved the URL
    params[:r] && params[:r] == stored_url
  end

  include Lev::HandleWith

  def set_sentry_user
    return if current_user.is_anonymous?
    Sentry.set_user(uuid: current_user.uuid)
  end

  def log_posthog(user, event, extra_props = {})
    OXPosthog.log(user, event, extra_props)
  end

  # Capture an event when there is no resolved user (e.g. a failed login or
  # password reset for an unknown email), keyed on the browser's anonymous
  # posthog-js distinct_id so these attempts are finally visible in PostHog.
  def log_posthog_anonymous(event, extra_props = {})
    OXPosthog.log_anonymous(posthog_anonymous_distinct_id, event, extra_props)
  end

  # posthog-js stores its distinct_id in a cookie named "ph_<api_key>_posthog"
  # whose value is a JSON blob. Pull the id out so a server-side event lines up
  # with the same anonymous person as the browser's client-side events.
  def posthog_anonymous_distinct_id
    cookie_name = "ph_#{Rails.application.secrets.posthog_project_api_key}_posthog"
    raw = cookies[cookie_name]
    return if raw.blank?

    # The cookie is client-controlled: anything that parses (`null`, `[]`, `"x"`)
    # must not blow up the request it is decorating.
    parsed = JSON.parse(raw)
    return unless parsed.is_a?(Hash)

    distinct_id = parsed['distinct_id']
    distinct_id if distinct_id.is_a?(String) && distinct_id.present?
  rescue JSON::ParserError
    nil
  end

  respond_to :html

  protected #################

  def allow_iframe_access
    @iframe_parent = params[:parent]

    if @iframe_parent.blank?
      response.headers.except! 'X-Frame-Options'
      return true
    end

    if Host.trusted? @iframe_parent
      response.headers.except! 'X-Frame-Options'
    else
      raise SecurityTransgression.new("#{@iframe_parent} is not allowed to iframe content")
    end
    true
  end
end
