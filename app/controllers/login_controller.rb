class LoginController < BaseController

  include LoginSignupHelper

  fine_print_skip :general_terms_of_use, :privacy_policy, except: :profile

  skip_before_action :authenticate_user!

  before_action :clear_signup_state, only: :login_form
  before_action :cache_client_app, only: :login_form
  before_action :cache_alternate_signup_url, only: :login_form
  before_action :student_signup_redirect, only: :login_form
  before_action :redirect_back, if: -> { signed_in? }, only: :login_form
  before_action :check_if_signup_complete, only: :login_post

  def login_form; end

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

        sign_in!(user, security_log_data: { 'email': @handler_result.outputs.email} )

        redirect_back
      },
      failure: lambda {
        email = @handler_result.outputs.email
        save_login_failed_email(email)
        security_log(:sign_in_failed, { reason: @handler_result.errors.first.code, email: email })
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
    if params[:go]&.strip&.downcase == 'student_signup'
      redirect_to signup_form_path(request.query_parameters.merge('role' => 'student'))
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
