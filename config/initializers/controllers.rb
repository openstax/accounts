ActionController::Base.class_exec do
  include SignInState

  protect_from_forgery

  helper OSU::OsuHelper, ApplicationHelper

  helper_method :current_user, :signed_in?

  if SECRET_SETTINGS[:beta_protection] != false
    protect_beta username: SECRET_SETTINGS[:beta_username],
                 password: SECRET_SETTINGS[:beta_password]
  end

  before_filter :authenticate_user!, :registration, :expired_password

  fine_print_require :general_terms_of_use, :privacy_policy, unless: :contracts_not_required

  protected

  def contracts_not_required
    @contracts_not_required =
      # Skip for API calls
      (request.format == :json) ||
      # Anonymous users can't sign contracts
      current_user.is_anonymous? ||
      # Skip if just arrived from an application that says skip
      Doorkeeper::Application.where(uid: params[:client_id] || session[:client_id])
                             .first
                             .try(:skip_terms?) ||
      # Skip if all of user's applications say skip
      (
        current_user.applications.any? &&
        current_user.applications.all?{|app| app.skip_terms? }
      )
  end

  def registration
    user = (request.format == :json) ? current_human_user : current_user
    return unless user.try(:is_temp?)
    store_url key: :registration_return_to

    respond_to do |format|
      format.html { redirect_to register_path }
      format.json { head(:forbidden) }
    end
  end

  def expired_password
    user = (request.format == :json) ? current_human_user : current_user
    identity = user.try(:identity)
    return unless identity.try(:password_expired?)

    code = GeneratePasswordResetCode.call(identity).outputs[:code]
    code_hash = { code: code }
    store_url key: :password_return_to

    respond_to do |format|
      format.html { redirect_to reset_password_path(code_hash) }
      # If we do this check (we probably should), then clients of the API
      # must handle this response and redirect the user appropriately.
      format.json { render :json => { expired_password: code_hash }.to_json }
    end
  end
end

# Layout is not inheritable in Rails 3.2
Rails.application.config.to_prepare do
  # Put this code inside the class_exec above in Rails 4
  # and remove it from ApplicationController
  [Doorkeeper::ApplicationController,
   FinePrint::ApplicationController].each do |klass|
    klass.layout 'application_body_only'
  end
end
