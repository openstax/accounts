class LoginController < ApplicationController

  include LoginSignupHelper

  skip_before_action :authenticate_user!

  before_action :cache_client_app, only: :login_form
  before_action :cache_alternate_signup_url, only: :login_form
  before_action :student_signup_redirect, only: :login_form
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
          security_log(:educator_resumed_signup_flow, message: 'User has not verified email address.')
          redirect_to verify_email_by_pin_form_path and return
        end

        sign_in!(user, security_log_data: {'email': @handler_result.outputs.email})
        # byebug
        if @current_user.student? || (@current_user.is_profile_complete? && @current_user.confirmed_faculty?)
          redirect_back(fallback_location: profile_path) and return
        end

        if @current_user.instructor? && !(@current_user.is_sheerid_unviable? || @current_user.is_profile_complete?)
          security_log(:educator_resumed_signup_flow, message: 'User needs to complete SheerID verification.')
          redirect_to sheerid_form_path and return
        end

        if @current_user.instructor? && (@current_user.is_needs_profile? || !@current_user.is_profile_complete?)
          security_log(:educator_resumed_signup_flow, message: 'User has not verified email address.')
          redirect_to profile_form_path and return
        end

        redirect_to profile_path
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

    # Now figure out where we should redirect the user...

    if return_url_specified_and_allowed?
      redirect_back(fallback_location: login_path)
    else
      session[ActionInterceptor.config.default_key] = nil

      # Compute a default redirect based on the referrer's scheme, host, and port.
      # Add the request's query onto this URL (a way for the logging-out app to
      # communicate state back to itself).
      url ||= begin
                referrer_uri = URI(request.referer)
                request_uri  = URI(request.url)
                if referrer_uri.host == request_uri.host
                  "#{root_url}?#{request_uri.query}"
                else
                  "#{referrer_uri.scheme}://#{referrer_uri.host}:#{referrer_uri.port}/?#{request_uri.query}"
                end
      rescue StandardError # in case the referer is bad (see #179)
                root_url
      end

      redirect_to url
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
  # has a message for students just letting them know how to sign up (they must
  # receive an email invitation).
  def cache_alternate_signup_url
    set_alternate_signup_url(params[:signup_at])
  end
end
