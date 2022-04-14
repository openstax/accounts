class SocialAuthController < ApplicationController
  include LoginSignupHelper

  fine_print_skip :general_terms_of_use, :privacy_policy

  before_action :restart_signup_if_missing_verified_user, only: [
    :confirm_oauth_info_form, :confirm_oauth_info_post
  ]

  # Log in (or sign up and then log in) a user using a social (OAuth) provider
  def oauth_callback
    if signed_in? && user_signin_is_too_old?
      reauthenticate_user!
    else
      handle_with(
        OauthCallback,
        logged_in_user: signed_in? && current_user,
        success: lambda {
          authentication = @handler_result.outputs.authentication
          user = @handler_result.outputs.user

          # Not activated means signup.
          # Only students can sign up with a social network.
          if user.student? && !user.activated?

            # legacy handling of the :needs_profile state
            # TODO: we could also just go change everyone from :needs_profile -> :incomplete_signup
            if user.state == 'needs_profile'
              user.update_attributes(state: :unverified, faculty_status: :incomplete_signup)
              save_unverified_user(user.id)

              SecurityLog.create(
                event_type: :user_updated,
                user:       user,
                event_data: {
                  state_was:        'needs_profile',
                  state_changed_to: 'incomplete_signup'
                }
              )
            end

            @first_name = user.first_name
            @last_name = user.last_name
            @email = @handler_result.outputs.email
            security_log(:student_social_sign_up, user: user, authentication_id: authentication.id)
            # must confirm their social info on signup
            render :confirm_social_info_form and return # TODO: if possible, update the route/path to reflect that this page is being rendered
          end

          sign_in!(user)
          security_log(:authenticated_with_social, user: user, authentication_id: authentication.id)
          redirect_back(fallback_location: profile_path)
        },
        failure: lambda {
          @email = @handler_result.outputs.email
          save_login_failed_email(@email)

          code = @handler_result.errors.first.code
          authentication = @handler_result.outputs.authentication
          case code
          when :should_redirect_to_signup
            redirect_to(
              login_path,
              notice: I18n.t(
                :"login_signup_form.should_social_signup",
                sign_up: view_context.link_to(I18n.t(:"login_signup_form.sign_up"), newflow_signup_path)
              )
            )
          when :authentication_taken
            security_log(:authentication_transfer_failed, authentication_id: authentication.id)
            redirect_to(profile_path, alert: I18n.t(:"controllers.sessions.sign_in_option_already_used"))
          when :email_already_in_use
            security_log(:email_already_in_use, email: @email, authentication_id: authentication.id)
            redirect_to(profile_path, alert: I18n.t(:"controllers.sessions.way_to_login_cannot_be_added"))
          when :mismatched_authentication
            security_log(:sign_in_failed, reason: "mismatched authentication")
            redirect_to(login_path, alert: I18n.t(:"controllers.sessions.mismatched_authentication"))
          else
            oauth = request.env['omniauth.auth']
            errors = @handler_result.errors.inspect
            last_exception = $!.inspect
            exception_backtrace = $@.inspect

            error_message = "[SocialAuthController#oauth_callback] IllegalState on failure: " +
                            "OAuth data: #{oauth}; error code: #{code}; " +
                            "handler errors: #{errors}; last exception: #{last_exception}; " +
                            "exception backtrace: #{exception_backtrace}"

            warn(error_message)
          end
        }
      )
    end
  end

  def confirm_oauth_info_form
    render :confirm_social_info_form
  end

  def confirm_oauth_info_post
    handle_with(
      ConfirmOauthInfo,
      user: unverified_user,
      contracts_required: !contracts_not_required,
      client_app: get_client_app,
      success: lambda {
        clear_signup_state
        sign_in!(@handler_result.outputs.user)
        security_log(:student_social_auth_confirmation_success)
        redirect_to signup_done_path
      },
      failure: lambda {
        security_log(:student_social_auth_confirmation_failed)
        render :confirm_social_info_form
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
end
