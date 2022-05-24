class UsersController < ApplicationController
  before_action :prevent_caching, only: [:update]

  def update
    OSU::AccessPolicy.require_action_allowed!(:update, current_user, current_user)

    respond_to do |format|
      format.json do
        if current_user.update(user_params)
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
    user_params = {}
    params[:value].each do |value|
      user_params.store(params[:name],value) if value.is_a?(String)
    end
    user_params
  end
end
