class ProfileController < ApplicationController

  fine_print_skip :general_terms_of_use, :privacy_policy, only: [:update]

  before_action :newflow_authenticate_user!, only: :profile
  before_action :ensure_complete_educator_signup, only: :profile
  before_action :prevent_caching

  def profile
  end

  def update
    OSU::AccessPolicy.require_action_allowed!(:update, current_user, current_user)

    respond_to do |format|
      format.json do
        if current_user.update_attributes(user_params.to_h)
          security_log :user_updated, user_params: user_params.to_h

          render json: { full_name: current_user.full_name }, status: :ok
        else
          render json: current_user.errors.full_messages.first, status: :unprocessable_entity
        end
      end
    end
  end

  private

  def user_params
    if params[:name] == 'username' # updating the username
      { 'username' => params[:value] }
    elsif params[:name] == 'profile_name' # updating the name
      name_split = params[:value].split(' ')
      { 'first_name': name_split[0...-1].join(' '), 'last_name': name_split[-1] }
    end
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
