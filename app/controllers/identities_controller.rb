class IdentitiesController < ApplicationController

  skip_before_filter :authenticate_user!, only: [:new, :forgot_password, :reset_password]

  fine_print_skip_signatures :general_terms_of_use,
                             :privacy_policy,
                             only: [:new, :forgot_password]

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
    handle_with(IdentitiesResetPassword,
                success: lambda {
                  return_to = session.delete(:return_to)
                  if return_to.present?
                    redirect_to return_to
                  else
                    render :reset_password, status: 200
                  end
                },
                failure: lambda {
                  render :reset_password, status: 400
                })
  end

end
