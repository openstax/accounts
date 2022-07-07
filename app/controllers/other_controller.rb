class OtherController < BaseController

  fine_print_skip :general_terms_of_use, :privacy_policy, only: [:update]

  before_action :newflow_authenticate_user!, only: :profile_newflow
  before_action :ensure_complete_educator_signup, only: :profile_newflow
  before_action :prevent_caching

  def profile_newflow
    render layout: 'application'
  end

  def exit_accounts
    if (redirect_param = extract_params(request.referrer)[:r])
      if Host.trusted?(redirect_param)
        redirect_to(redirect_param)
      else
        raise Lev::SecurityTransgression
      end
    elsif !signed_in? && (redirect_uri = extract_params(stored_url)[:redirect_uri])
      redirect_to(redirect_uri)
    else
      redirect_back # defined in the `action_interceptor` gem
    end
  end

  def update
    OSU::AccessPolicy.require_action_allowed!(:update, current_user, current_user)

    respond_to do |format|
      format.json do
        if current_user.update_attributes(user_params)
          security_log :user_updated, user_params: user_params

          render json: { full_name: current_user.full_name }, status: :ok
        else
          render json: current_user.errors.full_messages.first, status: :unprocessable_entity
        end
      end
    end
  end

  private

  def user_params
    params[:value].is_a?(String) ? \
      { params[:name] => params[:value] } : \
      params.require(:value).permit(:title, :first_name, :last_name, :suffix).to_h
  end

  def ensure_complete_educator_signup
    return if current_user.student?

    if decorated_user.newflow_edu_incomplete_step_3?
      security_log(:educator_resumed_signup_flow, message: 'User needs to complete SheerID verification. Redirecting.')
      redirect_to(educator_sheerid_form_path)
    elsif decorated_user.newflow_edu_incomplete_step_4?
      security_log(:educator_resumed_signup_flow, message: 'User needs to complete instructor profile. Redirecting.')
      redirect_to(educator_profile_form_path)
    end
  end

end
