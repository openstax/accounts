class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:login_form, :login_post]

  def login_form
    clear_signup_state
    cache_client_app
    cache_alternate_signup_url
    student_signup_redirect
  end

  def login_post
    handle_with(
      LogInUser,
      success: lambda {
        user = @handler_result.outputs.user

        if user.unverified?
          save_unverified_user(user.id)
          redirect_to verify_email_by_pin_form_path and return
        end

        sign_in!(user, security_log_data: {'email': @handler_result.outputs.email})

        if current_user.student? || current_user.is_profile_complete?
          redirect_back(fallback_location: profile_path)
        else
          # moved from educator_signup_flow_decorator, slated for refactoring because this is confusing
          if @current_step == 'login' && !current_user.is_profile_complete && current_user.sheerid_verification_id.blank?
            redirect_to(sheerid_form_path) and return
          elsif @current_step == 'login' && (current_user.sheerid_verification_id.present? || current_user.is_sheerid_unviable?)
            redirect_to(profile_form_path) and return
          elsif @current_step == 'educator_sheerid_form'
            if current_user.confirmed_faculty? || current_user.rejected_faculty? || current_user.sheerid_verification_id.present?
              #TODO: what is this?
            end
          elsif @current_step == 'educator_signup_form' && !current_user.is_anonymous?
            redirect_to(verify_email_by_pin_form_path) and return
          elsif @current_step == 'educator_email_verification_form' && @user.activated?
            if !current_user.student? && current_user.activated? && current_user.pending_faculty && current_user.sheerid_verification_id.blank?
              redirect_to(sheerid_form_path) and return
            elsif current_user.activated?
              redirect_to(profile_form_path) and return
            end
          else
            raise("Next step (#{@current_step}) uncaught in #{self.class.name}")
          end
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

        render :login_form and return
      }
    )
  end

  def reauthenticate_form; end

  def reauthenticate_post; end # TODO: post to login_post?

  def logout
    sign_out!
    redirect_back(fallback_location: login_path)
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
      redirect_back # defined in the `action_interceptor` gem
    end
  end

  protected

  def student_signup_redirect
    if params[:go]&.strip&.downcase == 'student_signup'
      request.query_parameters[:role] = 'student'
      redirect_to signup_form_path(request.query_parameters)
    elsif params[:go]&.strip&.downcase == 'signup'
      redirect_to signup_form_path(request.query_parameters)
    end
  end

  # Save (in the session) or clear the URL that the "Sign up" button in the FE points to.
  # -- Tutor uses this to send students who want to sign up, back to Tutor which
  # has a message for students just letting them know how to sign up (they must receive an email invitation).
  def cache_alternate_signup_url
    set_alternate_signup_url(params[:signup_at])
  end
end
