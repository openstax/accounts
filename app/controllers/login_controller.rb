class LoginController < ApplicationController

  include LoginSignupHelper

  fine_print_skip :general_terms_of_use, :privacy_policy

  before_action :cache_client_app, only: :login_form
  before_action :cache_alternate_signup_url, only: :login_form
  before_action :redirect_to_signup_if_go_param_present, only: :login_form
  before_action :redirect_back, if: -> { signed_in? }, only: :login_form

  def login_form
    clear_signup_state
    render :login_form
  end

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

        # TODO : this is not fun logic code.. find a better solution - but at least you don't have to hunt files for it
        if current_user.student? || user.is_profile_complete?
          redirect_back(fallback_location: profile_path)
        else
          if current_step == 'login' && !user.is_profile_complete && user.sheerid_verification_id.blank?
            redirect_to sheerid_form_path
          elsif current_step == 'login' && (user.sheerid_verification_id.present? || user.is_sheerid_unviable?)
            redirect_to profile_path
          elsif current_step == 'educator_sheerid_form'
            if user.confirmed_faculty? || user.rejected_faculty? || user.sheerid_verification_id.present?
              redirect_to profile_path
            end
          elsif current_step == 'educator_signup_form' && !user.is_anonymous?
            redirect_to verify_email_by_code_path
          elsif current_step == 'educator_email_verification_form' && user.activated?
            if !user.student? && user.activated? && user.pending_faculty && user.sheerid_verification_id.blank?
              redirect_to sheerid_form_path
            elsif user.activated?
              redirect_to profile_path
            end
          else
            raise("Next step (#{current_step}) uncaught in #{self.class.name}")
          end
        end
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
    sign_out!
    Sentry.set_user({}) if Rails.env.production?
    redirect_back(fallback_location: login_path)
  end

  protected ###############

  def redirect_to_signup_if_go_param_present
    if params[:go]&.strip&.downcase == 'student_signup'
      redirect_to signup_student_path(request.query_parameters)
    elsif params[:go]&.strip&.downcase == 'signup'
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
