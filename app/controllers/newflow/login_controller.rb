module Newflow
  class LoginController < BaseController

    include LoginSignupHelper

    GO_TO_STUDENT_SIGNUP = 'student_signup'
    GO_TO_SIGNUP = 'signup'

    fine_print_skip :general_terms_of_use, :privacy_policy, except: :profile_newflow

    before_action :redirect_to_signup_if_go_param_present, only: :login_form
    before_action :known_signup_role_redirect, only: :login_form
    before_action :cache_client_app, only: :login_form
    before_action :cache_alternate_signup_url, only: :login_form
    before_action :redirect_back, if: -> { signed_in? }, only: :login_form

    def login
      handle_with(
        AuthenticateUser,
        user_from_signed_params: session[:user_from_signed_params],
        success: lambda {
          clear_signup_state
          sign_in!(@handler_result.outputs.user)

          if current_user.student? || decorated_user.can_do?('redirect_back_upon_login')
            redirect_back # back to `r`edirect parameter. See `before_action :save_redirect`.
          else
            redirect_to(decorated_user.next_step)
          end
        },
        failure: lambda {
          email = @handler_result.outputs.email
          save_login_failed_email(email)

          code = @handler_result.errors.first.code
          case code
          when :cannot_find_user, :multiple_users, :incorrect_password, :too_many_login_attempts
            user = @handler_result.outputs.user
            security_log(:sign_in_failed, { reason: code, email: email })
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

    def redirect_to_signup_if_go_param_present
      if should_redirect_to_student_signup?
        redirect_to newflow_signup_student_path(request.query_parameters)
      elsif should_redirect_to_signup_welcome?
        redirect_to newflow_signup_path(request.query_parameters)
      end
    end

    def should_redirect_to_student_signup?
      params[:go]&.strip&.downcase == GO_TO_STUDENT_SIGNUP && Settings::FeatureFlags.student_feature_flag
    end

    def should_redirect_to_signup_welcome?
      params[:go]&.strip&.downcase == GO_TO_SIGNUP && (Settings::FeatureFlags.any_newflow_feature_flags?)
    end

    # save (in the seession) or clear the client_app that sent the user here
    def cache_client_app
      set_client_app(params[:client_id])
    end

    # Save (in the session) or clear the URL that the "Sign up" button in the FE points to.
    # -- Tutor uses this to send students who want to sign up, back to Tutor which
    # has a message for students just letting them know how to sign up (they must receive an email invitation).
    def cache_alternate_signup_url
      set_alternate_signup_url(params[:signup_at])
    end
  end
end
