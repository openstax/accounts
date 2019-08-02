class UsersController < ApplicationController

  fine_print_skip :general_terms_of_use, :privacy_policy, only: [:update]

  before_action :allow_iframe_access, only: [:edit, :update]
  before_action :prevent_caching, only: [:edit, :update]

  def edit
    OSU::AccessPolicy.require_action_allowed!(:update, current_user, current_user)
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

  def prevent_caching
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def user_params
    params[:value].is_a?(String) ? \
      {params[:name] => params[:value]} : \
      params.require(:value).permit(:title, :first_name, :last_name, :suffix).to_h
  end
end
