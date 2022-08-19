class LoginController < BaseController

  include LoginSignupHelper

  fine_print_skip :general_terms_of_use, :privacy_policy, except: :profile

  skip_before_action :authenticate_user!

  before_action :clear_signup_state, only: :login_form
  before_action :cache_client_app, only: :login_form
  before_action :cache_alternate_signup_url, only: :login_form
  before_action :student_signup_redirect, only: :login_form
  before_action :redirect_back, if: -> { signed_in? }, only: :login_form

  def login_post
    handle_with(
      LogInUser,
      success: lambda {
        user = @handler_result.outputs.user

        if Rails.env.production?
          Sentry.configure_scope do |scope|
            scope.set_tags(user_role: user.role.humanize)
            scope.set_user(uuid: user.uuid)
          end
        end

        # user has not verified email address - send them back to verify email form
        if user.unverified? || user.faculty_status == 'incomplete_signup'
          save_unverified_user(user.id)
          redirect_to(verify_email_by_pin_form_path) and return
        end

        sign_in!(user, security_log_data: { 'email': @handler_result.outputs.email} )

        # If the user is not a student, let's make sure they finished the signup process.
        unless user.student?
          unless current_user.is_sheerid_unviable? || current_user.is_profile_complete?
            security_log(:educator_resumed_signup_flow,
                         message: 'User needs to complete SheerID verification - return to SheerID verification form.')
            redirect_to sheerid_form_path and return
          end

          if current_user.is_needs_profile? || !current_user.is_profile_complete?
            security_log(:educator_resumed_signup_flow,
                         message: 'User has not completed profile - return to complete profile screen.')
            redirect_to profile_form_path and return
          end
        end

        redirect_back
      },
      failure: lambda {
        email = @handler_result.outputs.email
        save_login_failed_email(email)

        code = @handler_result.errors.first.code
        case code
        when :cannot_find_user, :multiple_users, :incorrect_password, :too_many_login_attempts
          security_log(:sign_in_failed, { reason: code, email: email })
        end

        render :login_form
      }
    )
  end

  def logout
    Sentry.set_user({}) if Rails.env.production?

    sign_out!
    redirect_back(fallback_location: login_path)
  end

  protected

  def student_signup_redirect
    if should_redirect_to_student_signup?
      redirect_to signup_form_path(request.query_parameters.merge('role' => 'student'))
    elsif should_redirect_to_signup_welcome?
      redirect_to signup_path(request.query_parameters)
    end
  end

  def should_redirect_to_student_signup?
    params[:go]&.strip&.downcase == 'student_signup'
  end

  def should_redirect_to_signup_welcome?
    params[:go]&.strip&.downcase == 'signup'
  end

  # Save (in the session) or clear the URL that the "Sign up" button in the FE points to.
  # -- Tutor uses this to send students who want to sign up, back to Tutor which
  # has a message for students just letting them know how to sign up (they must receive an email invitation).
  def cache_alternate_signup_url
    set_alternate_signup_url(params[:signup_at])
  end
end
