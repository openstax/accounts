class ExternalAccountCredentialsController < BaseController
  before_action :authenticate_external_user!, :validate_return_param!

  def new
    render_form
  end

  def create
    handle_with(
      CreateExternalAccountCredentials,
      success: -> {
        security_log :student_created_password, user: @user
        redirect_to @return_to
      },
      failure: -> {
        security_log :student_create_password_failed, user: @user
        render_form
      }
    )
  end

  protected

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
    @user = User.joins(:external_ids).find_by external_id: params[:external_id]

    # Cannot be used by users who can already login
    raise SecurityTransgression if @user.nil? || @user.can_login?
  end

  def validate_return_param!
    @return_to = params[:return_to]
    raise SecurityTransgression unless Host.trusted? @return_to
  end
end
