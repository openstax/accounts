class ExternalUserCredentialsController < Newflow::BaseController
  prepend_before_action :authenticate_external_user!, :validate_return_param!
  fine_print_skip :general_terms_of_use, :privacy_policy

  def new
    render_form
  end

  def create
    handle_with(
      CreateExternalUserCredentials,
      success: -> {
        security_log :student_created_password
        log_posthog(current_user, "user_created_with_external_credentials")
        redirect_to @return_to
      },
      failure: -> {
        security_log :student_create_password_failed
        render_form
      }
    )
  end

  protected

  def current_user
    @user
  end

  def render_form
    @contracts = [
      FinePrint.get_contract(:general_terms_of_use),
      FinePrint.get_contract(:privacy_policy)
    ]
    @signed_state = Rails.application.message_verifier('social_auth').generate({
      user_id: @user.id,
      return_to: @return_to
    }.to_json)

    render :new
  end

  def authenticate_external_user!
    @user = User.find_by(id: Doorkeeper::AccessToken.find_by(token: params[:token])&.resource_owner_id)

    # Cannot be used by users who can already login
    raise SecurityTransgression if @user.nil? || !@user.is_external?
  end

  def validate_return_param!
    @return_to = params[:return_to]
    raise SecurityTransgression unless Host.trusted? @return_to
  end
end
