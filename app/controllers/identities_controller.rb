class IdentitiesController < ApplicationController

  interceptor

  intercept_block = lambda {
    next unless current_user.identity.try(:should_reset_password?)
    identity = current_user.identity
    identity.generate_reset_code
    reset_password_path(code: identity.reset_code)
  }

  #intercept ::ApplicationController, &intercept_block
  intercept Doorkeeper::AuthorizationsController, &intercept_block

  skip_before_filter :authenticate_user!, only: [:new, :forgot_password,
                                                       :reset_password]

  fine_print_skip_signatures :general_terms_of_use,
                             :privacy_policy,
                             only: [:new, :forgot_password, :reset_password]

  def new
    @errors ||= env['errors']

    if !current_user.is_anonymous? && current_user.authentications.any?{|auth| auth.provider == 'identity'}
      redirect_to root_path, alert: "You are already have a simple username and password on your account!"
    end
  end

  def forgot_password
    if request.post?
      handle_with(IdentitiesForgotPassword,
                  success: lambda {
                    redirect_to root_path, notice: 'Password reset instructions sent to your email address!'
                  },
                  failure: lambda {
                    errors = @handler_result.errors.any?
                    render :forgot_password, status: errors ? 400 : 200
                  })
    end
  end

  def reset_password
    if !current_user.is_anonymous? && current_user.identity.should_reset_password?
      flash[:alert] = 'Your password has expired. Please enter a new password.'
    end
    handle_with(IdentitiesResetPassword,
                success: lambda {
                  return if !request.post?
                  sign_in @handler_result.outputs[:identity].user
                  redirect_back notice: 'Your password has been reset successfully! You have been signed in automatically.'
                },
                failure: lambda {
                  render :reset_password, status: 400
                })
  end

end
