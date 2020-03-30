module Newflow
  # Contains every action for login and signup
  class LoginSignupController < ApplicationController
    layout 'newflow_layout'

    skip_before_action :authenticate_user!
    skip_before_action :check_if_password_expired
    fine_print_skip :general_terms_of_use, :privacy_policy,
      except: [:profile_newflow, :verify_pin, :signup_done]

    before_action :newflow_authenticate_user!, only: [:profile_newflow]
    before_action :save_new_params_in_session, only: [:login_form, :welcome]
    before_action :store_authorization_url_as_fallback, only: [:login_form, :login, :student_signup_form, :student_signup]
    before_action :maybe_skip_to_sign_up, only: [:login_form]
    before_action :known_signup_role_redirect, only: [:login_form]
    before_action :restart_if_missing_unverified_user,
      only: [
        :verify_email, :verify_pin, :change_your_email, :confirmation_form,
        :confirmation_form_updated_email, :change_signup_email
      ]
    before_action :exit_newflow_signup_if_logged_in, only: [:student_signup_form, :welcome]
    before_action :set_active_banners
    before_action :cache_client_app, only: [:login, :welcome]
    before_action :redirect_back, if: -> { signed_in? }, only: :login_form

    def login
      handle_with(
        AuthenticateUser,
        user_from_signed_params: session[:user_from_signed_params],
        success: lambda {
          clear_newflow_state
          sign_in!(@handler_result.outputs.user)
          redirect_back # back to `r`eturn parameter. See `before_action :save_redirect`.
        },
        failure: lambda {
          save_login_failed_email(@handler_result.outputs.email)

          code = @handler_result.errors.first.code
          case code
          when :cannot_find_user, :multiple_users, :incorrect_password, :too_many_login_attempts
            user = @handler_result.outputs.user
            security_log(:sign_in_failed, { reason: code, user: user }) # also store email?
          end

          render :login_form
        }
      )
    end

    def educator_signup
      handle_with(
        EducatorSignup,
        success: lambda {
          save_unverified_user(@handler_result.outputs.user)
          security_log :educator_signed_up, { user: @handler_result.outputs.user }
          redirect_to confirmation_form_path
        },
        failure: lambda {
          email = @handler_result.outputs.email
          error_codes = @handler_result.errors.map(&:code)
          security_log(:educator_sign_up_failed, { reason: error_codes, email: email })
          render :educator_signup_form
        }
      )
    end

    def student_signup
      handle_with(
        StudentSignup,
        contracts_required: !contracts_not_required,
        client_app: get_client_app,
        user_from_signed_params: session[:user_from_signed_params],
        success: lambda {
          save_unverified_user(@handler_result.outputs.user)
          security_log :student_signed_up, { user: @handler_result.outputs.user }
          redirect_to confirmation_form_path
        },
        failure: lambda {
          email = @handler_result.outputs.email
          error_codes = @handler_result.errors.map(&:code)
          security_log(:student_sign_up_failed, { reason: error_codes, email: email })
          render :student_signup_form
        }
      )
    end

    def confirmation_form
      @first_name = unverified_user.first_name
      @email = unverified_user.email_addresses.first.value
    end

    def change_your_email
      @email = unverified_user.email_addresses.first.value
    end

    def change_signup_email
      handle_with(
        ChangeSignupEmail,
        user: unverified_user,
        success: lambda {
          redirect_to confirmation_form_updated_email_path
        },
        failure: lambda {
          render :change_your_email
        }
      )
    end

    def confirmation_form_updated_email
      @email = unverified_user.email_addresses.first.value
    end

    def verify_email_by_pin
      handle_with(
        VerifyEmailByPin,
        email_address: unverified_user.email_addresses.first,
        success: lambda {
          clear_newflow_state
          sign_in!(@handler_result.outputs.user)
          security_log(:student_verified_email)
          redirect_to signup_done_path
        },
        failure: lambda {
          @first_name = unverified_user.first_name
          @email = unverified_user.email_addresses.first.value
          security_log(:student_verified_email_failed, email: @email)
          render :confirmation_form
        }
      )
    end

    def verify_email_by_code
      handle_with(
        VerifyEmailByCode,
        success: lambda {
          clear_newflow_state
          sign_in!(@handler_result.outputs.user)
          security_log(:student_verified_email)
          redirect_to signup_done_path
        },
        failure: lambda {
          email = @handler_result.outputs.contact_info&.value
          user = @handler_result.outputs.user
          security_log(:student_verified_email_failed, email: email, user: user)
          redirect_to newflow_signup_path
        }
      )
    end

    def signup_done
      @first_name = current_user.first_name
      @email_address = current_user.email_addresses.first&.value
    end

    def profile_newflow
      render layout: 'application'
    end

    def logout
      sign_out!
      redirect_back(fallback_location: newflow_login_path)
    end

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

            if !user.is_activated?
              # not activated means signup
              save_unverified_user(user)
              @first_name = user.first_name
              @last_name = user.last_name
              @email = @handler_result.outputs.email
              security_log(:student_social_sign_up, user: user, authentication_id: authentication.id)
              # must confirm their social info on signup
              render :confirm_social_info_form and return
            end

            sign_in!(user)
            security_log(:student_authenticated_with_social, user: user, authentication_id: authentication.id)
            redirect_back(fallback_location: profile_newflow_path)
          },
          failure: lambda {
            @email = @handler_result.outputs.email
            save_login_failed_email(@email)

            code = @handler_result.errors.first.code
            authentication = @handler_result.outputs.authentication
            case code
            when :authentication_taken
              security_log(:authentication_transfer_failed, authentication_id: authentication.id)
              redirect_to(profile_newflow_path, alert: I18n.t(:"controllers.sessions.sign_in_option_already_used"))
            when :email_already_in_use
              security_log(:email_already_in_use, email: @email, authentication_id: authentication.id)
              redirect_to(profile_newflow_path, alert: I18n.t(:"controllers.sessions.way_to_login_cannot_be_added"))
            when :mismatched_authentication
              security_log(:sign_in_failed, reason: "mismatched authentication")
              redirect_to(newflow_login_path, alert: I18n.t(:"controllers.sessions.mismatched_authentication"))
            else
              raise IllegalState
            end
          }
        )
      end
    end

    def confirm_oauth_info
      handle_with(
        ConfirmOauthInfo,
        user: unverified_user,
        contracts_required: !contracts_not_required,
        client_app: get_client_app,
        success: lambda {
          clear_newflow_state
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
        reauthenticate_user!(redirect_back_to: profile_newflow_path)
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

    def forgot_password_form
      @email = login_failed_email
    end

    def send_reset_password_email
      handle_with(
        SendResetPasswordEmail,
        success: lambda {
          @email = @handler_result.outputs.email
          clear_newflow_state
          security_log :help_requested, user: current_user, email: @email
          sign_out!
          render :reset_password_email_sent
        },
        failure: lambda {
          user = @handler_result.outputs.user
          code = @handler_result.errors.first.code
          security_log :reset_password_failed, user: user, reason: code
          redirect_to newflow_login_path
        }
      )
    end

    def create_password_form
      create_or_change_password_form(kind: :create)
    end

    def create_password
      handle_with(
        CreatePassword,
        success: lambda {
          security_log(:student_created_password, user: @handler_result.outputs.user)
          redirect_to profile_newflow_url, notice: t(:"identities.add_success.message")
        },
        failure: lambda {
          security_log(:student_create_password_failed, user: @handler_result.outputs.user)
          render :create_password_form
        }
      )
    end

    def change_password_form
      create_or_change_password_form(kind: :change)
    end

    def change_password
      if signed_in? && user_signin_is_too_old?
        # This check again here in case a long time elapsed between the GET and the POST
        reauthenticate_user!
      elsif current_user.is_anonymous?
        raise Lev::SecurityTransgression
      else
        handle_with(
          ChangePassword,
          success: lambda {
            security_log :password_reset
            redirect_to profile_newflow_url, notice: t(:"identities.reset_success.message")
          },
          failure: lambda {
            security_log :password_reset_failed
            render :change_password_form, status: 400
          }
        )
      end
    end

    private #################

    def create_or_change_password_form(kind:)
      handle_with(
        FindUserByToken,
        success: lambda {
          if signed_in? && user_signin_is_too_old?
            reauthenticate_user!(redirect_back_to: change_password_form_path) and return
          elsif (user = @handler_result.outputs.user)
            sign_in!(user, { security_log_data: { type: 'token' } })
            security_log :help_requested, user: current_user
          end

          if kind == :change && current_user.identity.present?
            render(:change_password_form) and return
          elsif kind == :create || current_user.identity.nil?
            render(:create_password_form) and return
          end
        },
        failure: lambda {
          security_log(:help_request_failed, { params: request.query_parameters })
          render(status: 400)
        }
      )
    end

    def known_signup_role_redirect
      known_role = session.fetch(:signup_role, nil)

      if known_role && known_role == 'student'
        # TODO: when we create the Educator flow, redirect to there.
        redirect_to newflow_signup_student_path(request.query_parameters)
      end
    end

    def cache_client_app
      set_client_app(params[:client_id])
    end

    def save_unverified_user(user)
      session[:unverified_user_id] = user.id
    end

    def unverified_user
      id = session[:unverified_user_id]&.to_i
      return unless id.present?

      @unverified_user ||= User.find_by(id: id, state: 'unverified')
    end

    def exit_newflow_signup_if_logged_in
      if signed_in?
        redirect_back(fallback_location: profile_newflow_path(request.query_parameters))
      end
    end

    def restart_if_missing_unverified_user
      redirect_to newflow_signup_path unless unverified_user.present?
    end

    def save_login_failed_email(email)
      session[:login_failed_email] = email
    end

    def login_failed_email
      session[:login_failed_email]
    end

    def clear_unverified_user
      session.delete(:unverified_user_id)
    end

    def clear_login_failed_email
      session.delete(:login_failed_email)
    end

    def clear_newflow_state
      clear_login_failed_email
      clear_unverified_user
    end

    def set_active_banners
      return unless request.method == 'GET'

      @banners ||= Banner.active
    end

    def store_authorization_url_as_fallback
      # In case we need to redirect_back, but don't have something to redirect back
      # to (e.g. no authorization url or referrer), form and store as the fallback
      # an authorization URL.  Handles the case where the user got sent straight to
      # the login page.  Only works if we have know the client app.

      client_app = get_client_app
      return if client_app.nil?

      redirect_uri = client_app.redirect_uri.lines.first.chomp
      authorization_url = oauth_authorization_url(client_id: client_app.uid,
                                                  redirect_uri: redirect_uri,
                                                  response_type: 'code')

      store_fallback(url: authorization_url) unless authorization_url.nil?
    end
  end
end
