class SocialAuthController < ApplicationController
  include LoginSignupHelper

  fine_print_skip :general_terms_of_use, :privacy_policy

  skip_before_action :authenticate_user!, only: [ :oauth_callback, :confirm_oauth_info ]
  before_action :collect_info_during_social_signup, if: -> { signed_in? }, only: :oauth_callback
  
  # Log in (or sign up and then log in) a user using a social (OAuth) provider
  def oauth_callback
    @user = current_user
    if signed_in? && user_signin_is_too_old?
      reauthenticate_user!
    else
      handle_with(
        OauthCallback,
        success: lambda {
          authentication = @handler_result.outputs.authentication
          user = @handler_result.outputs.user

          sign_in!(user)

          security_log(:authenticated_with_social, user: user, authentication_id: authentication.id)
          redirect_back
        },
        failure: lambda {
          @email = @handler_result.outputs.email

          case @handler_result.errors.first.code
            # Another user has this email attached to their account
            when :mismatched_authentication
              security_log(:sign_in_failed, reason: "mismatched authentication", email: @email)
              redirect_to(login_path, alert: I18n.t(:"controllers.sessions.mismatched_authentication"))
            # The user is trying to sign up but they came from the login form, so redirect them to the sign up form
            when :should_redirect_to_signup
              redirect_to(login_path, notice: I18n.t(
                  :"login_signup_form.should_social_signup",
                  sign_up: view_context.link_to(I18n.t(:"login_signup_form.sign_up"), signup_path)
                ))
            # No user found with the given authentication, but a user *was* found with the given email address.
            # We will add the authentication to their existing account and then log them in.
            when :authentication_taken
              security_log(:authentication_transfer_failed, email: @email)
              redirect_to(profile_path, alert: I18n.t(:"controllers.sessions.sign_in_option_already_used"))
            when :email_already_in_use
              security_log(:email_already_in_use, email: @email)
              redirect_to(profile_path, alert: I18n.t(:"controllers.sessions.way_to_login_cannot_be_added"))
            else
              # Another unhandled error has occurred - Send the error to Sentry
              Sentry.capture_message(@handler_result.errors.inspect)
          end
        }
      )
    end
  end

  def confirm_oauth_info
    handle_with(
      ConfirmOauthInfo,
      user: current_user,
      contracts_required: !contracts_not_required,
      client_app: get_client_app,
      success: lambda {
        sign_in!(@handler_result.outputs.user)
        security_log(:student_social_auth_confirmation_success)
        redirect_to signup_done_path
      },
      failure: lambda {
        security_log(:student_social_auth_confirmation_failed)
        render :confirm_oauth_info
      }
    )
  end

  def remove_auth_strategy
    if signed_in? && user_signin_is_too_old?
      reauthenticate_user!(redirect_back_to: profile_path)
    else
      handle_with(
        AuthenticationsDelete,
        success: lambda do
          authentication = @handler_result.outputs.authentication
          security_log :authentication_deleted,
                      authentication_id: authentication.id,
                      authentication_provider: authentication.provider,
                      authentication_uid: authentication.uid
          render status: :ok,
                plain: (I18n.t :"controllers.authentications.authentication_removed",
                              authentication: params[:provider].titleize)
        end,
        failure: lambda do
          render status: 422, plain: @handler_result.errors.map(&:message).to_sentence
        end
      )
    end
  end

  protected

  def collect_info_during_social_signup
    if current_user.unverified? # needs social confirmation page for info
      @first_name = current_user.first_name
      @last_name = current_user.last_name
      @email = current_user.email_address.first
      security_log(:student_social_sign_up, user: user, authentication_id: authentication.id)
      redirect_to(confirm_oauth_info_path)
    end
  end
end
