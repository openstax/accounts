class PasswordManagementController < ApplicationController
  include LoginSignupHelper

  fine_print_skip :general_terms_of_use, :privacy_policy, only: [
    :forgot_password_form, :reset_password_email_sent
  ]

  skip_before_action :authenticate_user!

  def forgot_password_form
    @email = session[:login_failed_email]
  end

  def create_password_form
    handle_with(
      FindUserByToken,
      success: lambda {
        if signed_in? && user_signin_is_too_old?
          reauthenticate_user!(redirect_back_to: change_password_form_path) and return
        elsif (user = @handler_result.outputs.user)
          sign_in!(user, { security_log_data: { type: 'token' } })
          security_log :help_requested, user: current_user
        end
        render(:create_password_form) and return
      },
      failure: lambda {
        security_log(:help_request_failed, { params: request.query_parameters })
        Sentry.capture_message("Request for help failed", extra: {
          params: request.query_parameters
        })
        render(status: 400)
      }
    )
  end

  def change_password_form
    handle_with(
      FindUserByToken,
      success: lambda {
        if signed_in? && user_signin_is_too_old?
          reauthenticate_user!(redirect_back_to: change_password_form_path) and return
        elsif (user = @handler_result.outputs.user)
          sign_in!(user, { security_log_data: { type: 'token' } })
          security_log :help_requested, user: current_user
        end
        render(:change_password_form) and return
      },
      failure: lambda {
        security_log(:help_request_failed, { params: request.query_parameters })
        Sentry.capture_message("Request for help failed", extra: {
          params: request.query_parameters
        })
        render(status: 400)
      }
    )
  end
end
