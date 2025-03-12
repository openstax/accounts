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

  def log_posthog(user, event)
    return if user.nil? or user.is_anonymous? or Rails.env.test?
    begin
      OXPosthog.posthog.capture({
        distinct_id: user.uuid,
        event: event,
        properties: {
            '$set': { email: user.email_addresses&.first&.value,
                      name: user.full_name,
                      uuid: user.uuid,
                      role: user.role,
                      faculty_status: user.faculty_status,
                      school: user.school&.id,
                      recent_authentication_provider: user.authentications&.last&.provider,
                      authentication_method_count: user.authentications&.count,
                      salesforce_contact_id: user.salesforce_contact_id,
                      salesforce_lead_id: user.salesforce_lead_id,
        }
        }
      })
    rescue StandardError => e
      Sentry.capture_exception(e)
      return
    end
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
