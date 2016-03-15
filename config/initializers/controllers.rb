ActionController::Base.class_exec do
  use_openstax_exception_rescue

  include SignInState

  protect_from_forgery

  helper OSU::OsuHelper, ApplicationHelper

  helper_method :current_user, :signed_in?

  if SECRET_SETTINGS[:beta_protection] != false
    protect_beta username: SECRET_SETTINGS[:beta_username],
                 password: SECRET_SETTINGS[:beta_password]
  end


  before_filter :authenticate_user!
  # before_filter :registration
  before_filter :expired_password

  fine_print_require :general_terms_of_use, :privacy_policy, unless: :disable_fine_print

  protected

  def disable_fine_print
    contracts_not_required(client_id: params[:client_id] || session[:client_id]) ||
    current_user.is_anonymous?
  end

  include ContractsNotRequired

  # def registration
  #   return true if request.format != :html
  #   return unless current_user.is_temp?
  #   redirect_to registration_complete_path
  # end

  def expired_password
    return true if request.format != :html

    identity = current_user.identity
    return unless identity.try(:password_expired?)

    code = GeneratePasswordResetCode.call(identity).outputs[:code]
    code_hash = { code: code }
    store_url key: :password_return_to

    redirect_to reset_password_path(code_hash)
  end
end

# Layout is not inheritable in Rails 3.2
Rails.application.config.to_prepare do
  # Put this code inside the class_exec above in Rails 4
  # and remove it from ApplicationController
  [Doorkeeper::ApplicationController,
   FinePrint::ApplicationController].each do |klass|
    klass.layout 'application'
  end
end
