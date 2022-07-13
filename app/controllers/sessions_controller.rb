class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]
  before_action :cache_client_app, :cache_alternate_signup_url, :redirect_to_signup_if_go_param_present,
                only: :new

  include LoginSignupHelper

  fine_print_skip :general_terms_of_use, :privacy_policy, except: :profile

  skip_before_action :authenticate_user!

  before_action :cache_client_app, only: :login_form
  before_action :cache_alternate_signup_url, only: :login_form
  before_action :redirect_to_signup_if_go_param_present, only: :login_form
  before_action :redirect_back, if: -> { signed_in? }, only: :login_form

  def login_post
    handle_with(
      LogInUser,
      success: lambda {
        clear_signup_state
        user = @handler_result.outputs.user

        if user.unverified?
          save_unverified_user(user.id)

          redirect_to(verify_email_by_pin_form_path)

          return
        end

        sign_in!(user, security_log_data: {'email': @handler_result.outputs.email})

        if current_user.student? || decorated_user.can_do?('redirect_back_upon_login')
          redirect_back(fallback_location: profile_path)
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

        render :login
      }
    )
  end

  def logout
    sign_out!
    redirect_back(fallback_location: login_path)
  end

  def reauthenticate; end

  protected

  def redirect_to_signup_if_go_param_present
    if should_redirect_to_student_signup?
      redirect_to signup_form_path(request.query_parameters.merge('role' => 'student'))
    elsif should_redirect_to_signup_welcome?
      redirect_to signup_path(request.query_parameters)
    end
  end

  # Save (in the session) or clear the URL that the "Sign up" button in the FE points to.
  # -- Tutor uses this to send students who want to sign up, back to Tutor which
  # has a message for students just letting them know how to sign up (they must receive an email invitation).
  def cache_alternate_signup_url
    set_alternate_signup_url(params[:signup_at])
  end
end
