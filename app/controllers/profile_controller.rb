class ProfileController < BaseController

  skip_before_action :authenticate_user!, only: :exit_accounts
  before_action :ensure_complete_educator_signup, only: :profile
  before_action :prevent_caching, only: :profile

  def profile
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
    if params[:username]
      { 'username' => params[:value] }
    elsif params[:profile_name]
      name_split = params[:profile_name].split(' ')
      { 'first_name': name_split[0...-1].join(' '), 'last_name': name_split[-1] }
    end
  end

  def ensure_complete_educator_signup
    return if current_user.student?

    if decorated_user.edu_incomplete_step_3?
      security_log(:educator_resumed_signup_flow, message: 'User needs to complete SheerID verification. Redirecting.')
      redirect_to(sheerid_form_path)
    elsif decorated_user.edu_incomplete_step_4?
      security_log(:educator_resumed_signup_flow, message: 'User needs to complete instructor profile. Redirecting.')
      redirect_to(profile_form_path)
    end
  end

end
