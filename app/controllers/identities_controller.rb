class IdentitiesController < ApplicationController

  skip_before_filter :authenticate_user!, :expired_password, :finish_sign_up,
                     only: [:new, :reset_password]

  fine_print_skip :general_terms_of_use, :privacy_policy,
                  only: [:new, :reset_password]

  def new
    @errors ||= env['errors']

    if !current_user.is_anonymous? && current_user.authentications.any?{|auth| auth.provider == 'identity'}
      redirect_to root_path, alert: "You already have a simple username and password on your account!"
    else
      store_fallback
    end
  end

  def update
    @active_tab = :password
    handle_with(IdentitiesUpdate,
                success: lambda { redirect_to profile_path, notice: 'Password changed' },
                failure: lambda { render 'users/edit', status: 400 })
  end

  def reset_password
    if !current_user.is_anonymous? && current_user.identity.password_expired?
      store_fallback key: :password_return_to
      flash[:alert] = 'Your password has expired. Please enter a new password.'
    end
    handle_with(IdentitiesResetPassword,
                success: lambda {
                  return if !request.post?
                  sign_in! @handler_result.outputs[:identity].user
                  redirect_back key: :password_return_to,
                                notice: 'Your password has been reset successfully! You have been signed in automatically.'
                },
                failure: lambda {
                  render :reset_password, status: 400
                })
  end

end
