class UsersController < ApplicationController

  fine_print_skip :general_terms_of_use, :privacy_policy, only: [:edit, :update]

  def edit
    OSU::AccessPolicy.require_action_allowed!(:update, current_user, current_user)
  end

  def update
    OSU::AccessPolicy.require_action_allowed!(:update, current_user, current_user)

    respond_to do |format|
      if current_user.update_attributes(user_params)
        security_log :user_updated, user_params: user_params

        format.json {
          render json: { full_name: current_user.full_name }, status: :ok
        }
      else
        format.json {
          render json: current_user.errors.full_messages.first, status: :unprocessable_entity
        }
      end
    end
  end

  private

  def user_params
    params[:value].is_a?(Hash) ? params[:value] : {params[:name] => params[:value]}
  end

end
