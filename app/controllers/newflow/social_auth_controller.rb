module Newflow
  class SocialAuthController < BaseController
    include LoginSignupHelper

    fine_print_skip :general_terms_of_use, :privacy_policy

    # Log in (or sign up and then log in) a user using a social (OAuth) provider
    def oauth_callback
      # omniauth.auth is nil when this route is hit directly without going through
      # OmniAuth middleware (e.g. bots, expired sessions, unknown provider).
      unless request.env['omniauth.auth']
        redirect_to(newflow_login_path, alert: I18n.t(:"controllers.sessions.trouble_with_provider")) and return
      end

      # If state is not assigned, then doorkeeper uses a random string
      # So if state is not decodable we assume they are in the normal signup flow
      @token = verify_token(params[:state])
      if @token.present?
        logged_in_user = User.find @token['user_id']
        is_external = true
      elsif signed_in? && user_signin_is_too_old?
        return reauthenticate_user!
      else
        logged_in_user = signed_in? && current_user
        is_external = false
      end

      handle_with(
        OauthCallback,
        logged_in_user: logged_in_user,
        success: -> {
          authentication = @handler_result.outputs.authentication
          user = @handler_result.outputs.user

          if user.student? && !user.activated?
            # Not activated means signup.
            # Only students can sign up with a social network.
            unverified_user = ensure_unverified_user(user)

            # If a token is present, we just get the user from that in confirm_oauth_info
            # Otherwise we save the unverified user in the session to be used there
            save_unverified_user(unverified_user.id) if @token.nil?

            @first_name = user.first_name
            @last_name = user.last_name
            @email = @handler_result.outputs.email
            security_log(:student_social_sign_up, user: user, authentication_id: authentication.id)
            log_posthog(user, 'student_signup_social', { provider: authentication.provider, client_app: get_client_app&.name })
            # must confirm their social info on signup
            render :confirm_social_info_form and return # TODO: if possible, update the route/path to reflect that this page is being rendered
          end

          sign_in!(user)
          log_posthog(user, 'user_logged_in_social', { provider: authentication.provider, client_app: get_client_app&.name })
          security_log(:authenticated_with_social, user: user, authentication_id: authentication.id)
          redirect_back(fallback_location: profile_newflow_path)

        },
        failure: -> {
          @email = @handler_result.outputs.email
          save_login_failed_email(@email)

          code = @handler_result.errors.first.code
          authentication = @handler_result.outputs.authentication

          case code
          when :should_redirect_to_signup
            redirect_to(
              error_path(is_external, code),
              notice: I18n.t(
                :"login_signup_form.should_social_signup",
                sign_up: view_context.link_to(I18n.t(:"login_signup_form.sign_up"), newflow_signup_path)
              )
            )
          when :authentication_taken || 'taken'
            security_log(:authentication_transfer_failed, authentication_id: authentication.id)
            redirect_to(error_path(is_external, code), alert: I18n.t(:"controllers.sessions.sign_in_option_already_used"))
          when :email_already_in_use
            security_log(:email_already_in_use, email: @email, authentication_id: authentication.id)
            redirect_to(error_path(is_external, code), alert: I18n.t(:"controllers.sessions.way_to_login_cannot_be_added"))
          when :mismatched_authentication
            security_log(:sign_in_failed, reason: "mismatched authentication")
            redirect_to(error_path(is_external, code), alert: I18n.t(:"controllers.sessions.mismatched_authentication"))
          else
            oauth = request.env['omniauth.auth']
            errors = @handler_result.errors.inspect
            last_exception = $!.inspect
            exception_backtrace = $@.inspect

            error_message = "[SocialAuthController#oauth_callback] IllegalState on failure: " +
                            "OAuth data: #{oauth}; error code: #{code}; " +
                            "handler errors: #{errors}; last exception: #{last_exception}; " +
                            "exception backtrace: #{exception_backtrace}"

            # Send the error to Sentry
            Sentry.capture_message(error_message)
            redirect_to(newflow_login_path, alert: I18n.t(:"controllers.sessions.trouble_with_provider", default: "We had trouble signing you in with your social account. Please try again."))
          end
        }
      )
    end

    def confirm_oauth_info
      @token = verify_token(params[:token])
      if @token.present?
        user = User.find(@token['user_id'])
        return_to = @token['return_to']
      else
        return redirect_to(newflow_signup_path) unless unverified_user.present?
        user = unverified_user
        return_to = signup_done_path
      end

      handle_with(
        ConfirmOauthInfo,
        user: user,
        contracts_required: !contracts_not_required,
        client_app: get_client_app,
        success: -> {
          clear_signup_state
          sign_in!(@handler_result.outputs.user)
          security_log(:student_social_auth_confirmation_success)
          log_posthog(@handler_result.outputs.user, 'student_signup_done')
          redirect_to return_to
        },
        failure: -> {
          security_log(:student_social_auth_confirmation_failed)
          @first_name = user.first_name
          @last_name = user.last_name
          @email = @handler_result.outputs.email
          render :confirm_social_info_form
        }
      )
    end

    def remove_auth_strategy
      if signed_in? && user_signin_is_too_old?
        reauthenticate_user!(redirect_back_to: profile_newflow_path)
      else
        handle_with(
          AuthenticationsDelete,
          success: -> do
            authentication = @handler_result.outputs.authentication
            security_log :authentication_deleted,
                        authentication_id: authentication.id,
                        authentication_provider: authentication.provider,
                        authentication_uid: authentication.uid
            render status: :ok,
                  plain: (I18n.t :"controllers.authentications.authentication_removed",
                                authentication: params[:provider].titleize)
          end,
          failure: -> do
            render status: 422, plain: @handler_result.errors.map(&:message).to_sentence
          end
        )
      end
    end

    private #################

    def verify_token(token)
      JSON.parse(Rails.application.message_verifier('social_auth').verify(token)) rescue nil
    end

    def error_path(is_external, code)
      return new_external_user_credentials_path if is_external

      case code
      when :should_redirect_to_signup, :mismatched_authentication
        newflow_login_path
      when :authentication_taken, :email_already_in_use
        profile_newflow_path
      end
    end

    def ensure_unverified_user(user)
      EnsureUnverifiedUser.call(user).outputs.user
    end
  end
end
