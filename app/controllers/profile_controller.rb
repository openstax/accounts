class ProfileController < ApplicationController

  fine_print_skip :general_terms_of_use, :privacy_policy, only: [:update]

  before_action :prevent_caching, :authenticate_user!

  def profile
    # redirect_instructors_needing_to_complete_signup
  end

  def update
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

  # def redirect_instructors_needing_to_complete_signup
  #   return if current_user.student?
  #
  #   if current_user.sheerid_verification_id.blank? && current_user.pending_faculty? && !current_user.is_educator_pending_cs_verification
  #     security_log(:educator_resumed_signup_flow, message: 'User needs to complete SheerID verification. Redirecting.')
  #     redirect_to(sheerid_form_path) and return
  #   elsif !current_user.is_profile_complete?
  #     security_log(:educator_resumed_signup_flow, message: 'User needs to complete instructor profile. Redirecting.')
  #     redirect_to(profile_form_path) and return
  #   end
  # end

end
