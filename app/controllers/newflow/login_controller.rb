module Newflow
  class LoginController < BaseController
    include LoginSignupHelper

    layout 'newflow_layout'

    fine_print_skip :general_terms_of_use, :privacy_policy, except: :profile_newflow

    before_action :save_new_params_in_session
    before_action :maybe_skip_to_sign_up
    before_action :known_signup_role_redirect
    before_action :redirect_back, if: -> { signed_in? }, only: :login_form
    before_action :cache_client_app, only: [:login_form]

    def login
      handle_with(
        AuthenticateUser,
        user_from_signed_params: session[:user_from_signed_params],
        success: lambda {
          clear_newflow_state
          sign_in!(@handler_result.outputs.user)
          redirect_back # back to `r`edirect parameter. See `before_action :save_redirect`.
        },
        failure: lambda {
          save_login_failed_email(@handler_result.outputs.email)

          code = @handler_result.errors.first.code
          case code
          when :cannot_find_user, :multiple_users, :incorrect_password, :too_many_login_attempts
            user = @handler_result.outputs.user
            security_log(:sign_in_failed, { reason: code, user: user }) # also store email?
          end

          render :login_form
        }
      )
    end

    def logout
      sign_out!
      redirect_back(fallback_location: newflow_login_path)
    end

    protected ###############

    def cache_client_app
      set_client_app(params[:client_id])
    end
  end
end
