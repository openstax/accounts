class IdentitiesController < ApplicationController

  acts_as_interceptor

  skip_before_filter :authenticate_user!,
                     only: [:new, :forgot_password, :reset_password]
  skip_interceptor :expired_password, :registration,
                     only: [:new, :forgot_password, :reset_password]

  fine_print_skip_signatures :general_terms_of_use,
                             :privacy_policy,
                             only: [:new, :forgot_password, :reset_password]

  def new
    @errors ||= env['errors']

    if !current_user.is_anonymous? && current_user.authentications.any?{|auth| auth.provider == 'identity'}
      without_interceptor { redirect_to root_path, alert: "You are already have a simple username and password on your account!" }
    end
  end

  def update
    handle_with(IdentitiesUpdate,
                success: lambda { redirect_to profile_path, notice: 'Password changed' },
                failure: lambda { render 'users/edit', status: 400 })
  end

  def forgot_password
    if request.post?
      handle_with(IdentitiesForgotPassword,
                  success: lambda { without_interceptor {
                    redirect_to root_path, notice: 'Password reset instructions sent to your email address!'
                  }},
                  failure: lambda {
                    errors = @handler_result.errors.any?
                    render :forgot_password, status: errors ? 400 : 200
                  })
    end
  end

  def reset_password
    if !current_user.is_anonymous? && current_user.identity.password_expired?
      flash[:alert] = 'Your password has expired. Please enter a new password.'
    end
    handle_with(IdentitiesResetPassword,
                success: lambda {
                  return if !request.post?
                  sign_in! @handler_result.outputs[:identity].user
                  redirect_back notice: 'Your password has been reset successfully! You have been signed in automatically.'
                },
                failure: lambda {
                  render :reset_password, status: 400
                })
  end

end
