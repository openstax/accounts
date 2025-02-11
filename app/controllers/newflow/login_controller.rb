module Newflow
  class LoginController < BaseController

    include LoginSignupHelper

    fine_print_skip :general_terms_of_use, :privacy_policy, except: :profile_newflow

    before_action :cache_client_app, only: :login_form
    before_action :known_signup_role_redirect, only: :login_form
    before_action :cache_alternate_signup_url, only: :login_form
    before_action :redirect_to_signup_if_go_param_present, only: :login_form
    before_action :redirect_to_sign_privacy_notice, if: -> { signed_in? && !did_user_sign_recent_privacy_notice? }, only: [:login, :login_form]
    before_action :redirect_back, if: -> { signed_in? && did_user_sign_recent_privacy_notice? }, only: :login_form

    def login
      handle_with(
        LogInUser,
        success: lambda {
          clear_signup_state
          user = @handler_result.outputs.user

          if user.unverified?
            save_unverified_user(user.id)

            if user.student?
              redirect_to(student_email_verification_form_path)
            else
              redirect_to(educator_email_verification_form_path)
            end

            return
          end

          sign_in!(user, security_log_data: {'email': @handler_result.outputs.email})
          log_posthog(user, 'user_logged_in')

          if current_user.student? || !current_user.is_newflow? || (edu_newflow_activated? && decorated_user.can_do?('redirect_back_upon_login'))
            did_user_sign_recent_privacy_notice? ? redirect_back : redirect_to_sign_privacy_notice
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
            security_log(:sign_in_failed, { reason: code, email: email, user: user })
          end

          render :login_form
        }
      )
    end

    def logout
      log_posthog(current_user, 'user_logged_out')
      sign_out!
      Sentry.set_user({}) if Rails.env.production?
      redirect_back(fallback_location: newflow_login_path)
    end

    protected ###############

    def redirect_to_signup_if_go_param_present
      if params[:go]&.strip&.downcase == 'student_signup'
        redirect_to newflow_signup_student_path(request.query_parameters)
      elsif params[:go]&.strip&.downcase == 'signup'
        redirect_to newflow_signup_path(request.query_parameters)
      end
    end

    # Save (in the session) or clear the URL that the "Sign up" button in the FE points to.
    # -- Tutor uses this to send students who want to sign up, back to Tutor which
    # has a message for students just letting them know how to sign up (they must receive an email invitation).
    def cache_alternate_signup_url
      set_alternate_signup_url(params[:signup_at])
    end

    def did_user_sign_recent_privacy_notice?
      contract = FinePrint.get_contract(:privacy_policy)
      contract.signed_by?(current_user) ? true : false
    end

    def redirect_to_sign_privacy_notice
      contract = FinePrint.get_contract(:privacy_policy)
      redirect_to pose_term_url(name: contract.name, :r => session[:return_to]) and nil
    end
  end
end
