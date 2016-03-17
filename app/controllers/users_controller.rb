class UsersController < ApplicationController

  skip_before_filter :registration, only: [:edit, :update]

  fine_print_skip :general_terms_of_use, :privacy_policy, only: [:edit, :update]

  def edit
    OSU::AccessPolicy.require_action_allowed!(:update, current_user, current_user)
  end

  def update
    OSU::AccessPolicy.require_action_allowed!(:update, current_user, current_user)
    if current_user.update_attributes(user_params)
      redirect_to profile_path, notice: 'Your profile has been updated. These changes may take a few minutes to propagate to the entire site.'
    else
      flash.now[:alert] ||= []
      current_user.errors.full_messages.each do |msg|
        flash.now[:alert] << msg
      end
      render :edit, status: 400
    end
  end

  private

  def user_params
    up = params[:user]
    return {} unless up.is_a? Hash
    up = up.slice(:title, :first_name, :last_name, :suffix)
    up[:full_name] = "#{up[:first_name]} #{up[:last_name]} #{up[:suffix]}"
    up
  end

end
