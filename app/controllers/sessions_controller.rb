class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:login_form, :login_post]

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
        user = @handler_result.outputs.user

        if user.unverified?
          save_unverified_user(user.id)

          redirect_to(verify_email_by_pin_form_path)

          return
        end

        sign_in!(user, security_log_data: {'email': @handler_result.outputs.email})

        if current_user.student? || current_user.is_profile_complete?
          redirect_back
        else
          redirect_to(finish_signing_up)
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

  def reauthenticate_form; end

  def reauthenticate_post; end # TODO: post to login_post?

  def logout
    sign_out!
    redirect_back
  end

  def exit_accounts
    if (redirect_param = extract_params(request.referrer)[:r])
      if Host.trusted?(redirect_param)
        redirect_to(redirect_param)
      else
        raise Lev::SecurityTransgression
      end
    elsif !signed_in? && (redirect_uri = extract_params(stored_url)[:redirect_uri])
      redirect_to(redirect_uri)
    else
      redirect_back
    end
  end

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

  def finish_signing_up
    # moved from educator_signup_flow_decorator, slated for refactoring because this is confusing
    if @current_step == 'login' && !current_user.is_profile_complete && current_user.sheerid_verification_id.blank?
      sheerid_form_path
    elsif @current_step == 'login' && (current_user.sheerid_verification_id.present? || current_user.is_sheerid_unviable?)
      profile_form_path
    elsif @current_step == 'educator_sheerid_form'
      if current_user.confirmed_faculty? || current_user.rejected_faculty? || current_user.sheerid_verification_id.present?
        #TODO: what is this?
      end
    elsif @current_step == 'educator_signup_form' && !current_user.is_anonymous?
      verify_email_by_pin_form_path
    elsif @current_step == 'educator_email_verification_form' && @user.activated?
      if !current_user.student? && current_user.activated? && current_user.pending_faculty && current_user.sheerid_verification_id.blank?
        sheerid_form_path
      elsif current_user.activated?
        profile_form_path
      end
    else
      raise("Next step (#{@current_step}) uncaught in #{self.class.name}")
    end
  end
end
