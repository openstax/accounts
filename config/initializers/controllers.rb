ActionController::Base.class_exec do

  use_openstax_exception_rescue

  protect_from_forgery

  layout 'application'

  include OSU::OsuHelper
  include ApplicationHelper
  include SignInState
  include LocaleSelector

  helper OSU::OsuHelper, ApplicationHelper, SignInState

  secrets = Rails.application.secrets
  protect_beta(username: secrets[:beta_username], password: secrets[:beta_password]) \
    if Rails.application.secrets[:beta_protection]

  before_filter :authenticate_user!
  before_filter :finish_sign_up
  before_filter :expired_password
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
    contracts_not_required(client_id: params[:client_id] || session[:client_id]) ||
    current_user.is_anonymous?
  end

  include ContractsNotRequired

  def finish_sign_up
    return true if request.format != :html
    return unless current_user.is_new_social?
    redirect_to signup_social_path
  end

  def expired_password
    return true if request.format != :html

    identity = current_user.identity
    return unless identity.try(:password_expired?)

    code = GeneratePasswordResetCode.call(identity).outputs[:code]
    code_hash = { code: code }
    store_url key: :password_return_to

    redirect_to reset_password_path(code_hash)
  end

  def set_last_signin_provider(provider)
    cookies.signed[:last_signin_provider] = provider
  end

  def last_signin_provider
    cookies.signed[:last_signin_provider]
  end

end
