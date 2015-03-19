class UsersController < ApplicationController

  skip_before_filter :registration, only: [:register]

  fine_print_skip_signatures :general_terms_of_use,
                             :privacy_policy,
                             only: [:register]

  def edit
    OSU::AccessPolicy.require_action_allowed!(:update, current_user, current_user)
  end

  def update
    OSU::AccessPolicy.require_action_allowed!(:update, current_user, current_user)
    if current_user.update_attributes(user_params)
      redirect_to profile_path, notice: 'Profile updated'
    else
      flash.now[:alert] ||= []
      current_user.errors.full_messages.each do |msg|
        flash.now[:alert] << msg
      end
      render :edit, status: 400
    end
  end

  def register
    if request.put?
      handle_with(UsersRegister,
                  success: lambda { redirect_back key: :registration_return_to },
                  failure: lambda {
                    errors = @handler_result.errors.any?
                    render :register, status: errors ? 400 : 200
                  })
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
