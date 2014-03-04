class IdentitiesController < ApplicationController

  skip_before_filter :authenticate_user!, only: [:new, :forgot_password]

  def new
    @errors ||= env['errors']

    if !current_user.is_anonymous? && current_user.authentications.any?{|auth| auth.provider == 'identity'}
      redirect_to root_path, alert: "You are already have a simple username and password on your account!"
    end
  end

  def forgot_password
    if request.post?
      handle_with(ForgotPassword,
                  success: lambda {
                    redirect_to root_path, notice: 'Password reset instructions sent to your email address!'
                  },
                  failure: lambda {
                    errors = @handler_result.errors.any?
                    render :forgot_password, status: errors ? 400 : 200
                  })
    end
  end

end
