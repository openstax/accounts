module Newflow
    # Contains every action for login and signup
    class LoginSignupController < ApplicationController
    layout 'newflow_layout'
    skip_before_action :authenticate_user!
    before_action :newflow_authenticate_user!, only: [:profile_newflow]
    before_action :restart_if_missing_unverified_user, only: [:verify_email, :verify_pin, :change_your_email]
    before_action :exit_newflow_signup_if_logged_in, only: [:login_form, :signup_form, :student_signup_form, :welcome]
    before_action :set_active_banners
    before_action :cache_client_app, only: [:login, :welcome]
    skip_before_action :check_if_password_expired
    fine_print_skip :general_terms_of_use, :privacy_policy,
                    except: [:profile_newflow, :verify_pin, :signup_done]

    def login
      handle_with(
        AuthenticateUser,
        success: lambda {
          clear_newflow_state
          sign_in!(@handler_result.outputs.user)
          security_log(:sign_in_successful)
          redirect_back # back to `r`eturn parameter. See `before_action :save_redirect`.
        },
        failure: lambda {
          security_log :sign_in_failed, event_data: { reason: @handler_result.errors.first.code }
          save_login_failed_email(@handler_result.outputs.email)
          render :login_form
        }
      )
    end

    def student_signup
      handle_with(
        StudentSignup,
        contracts_required: !contracts_not_required,
        client_app: get_client_app,
        success: lambda {
          save_unverified_user(@handler_result.outputs.user)
          security_log :sign_up_successful, event_data: { user: @handler_result.outputs.user }
          redirect_to confirmation_form_path
        },
        failure: lambda {
          render :student_signup_form
        }
      )
    end

    def confirmation_form
      redirect_to newflow_signup_path and return unless unverified_user.present?

      @first_name = unverified_user.first_name
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
      redirect_to newflow_signup_path and return unless unverified_user.present?

      @email = unverified_user.email_addresses.first.value
    end

    def verify_email_by_pin
      handle_with(
        VerifyEmailByPin,
        email_address: unverified_user.email_addresses.first,
        success: lambda {
          clear_newflow_state
          sign_in!(@handler_result.outputs.user)
          security_log :sign_up_successful
          redirect_to signup_done_path
        },
        failure: lambda {
          @first_name = unverified_user.first_name
          @email = unverified_user.email_addresses.first.value
          security_log :sign_up_successful
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
          security_log :sign_up_successful
          redirect_to signup_done_path
        },
        failure: lambda {
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

    def reset_password_form
      @email = login_failed_email
    end

    def reset_password
      handle_with(
        ResetPassword,
        success: lambda {
          @email = @handler_result.outputs.email
          clear_newflow_state
          sign_out!

          security_log :help_requested, user: @handler_result.outputs.user
          render :reset_password_email_sent
        },
        failure: lambda {
          security_log :help_request_failed, user: @handler_result.outputs.user
          render :reset_password_form
        }
      )
    end

    def change_password_form
      handle_with(
        FindUserByToken,
        success: lambda {
          sign_in!(@handler_result.outputs.user)
          security_log :help_requested, user: @handler_result.outputs.user # TODO: 'help_requested'??
          render :change_password_form
        },
        failure: lambda {
          security_log :help_request_failed, token: params[:token]
          render status: 400
        }
      )
    end

    def change_password
      # TODO: This check again here in case a long time elapsed between the GET and the POST
      # user_signin_is_too_old?
      # reauthenticate_user_if_signin_is_too_old!

      handle_with(
        ChangePassword,
        user: current_user,
        success: lambda {
          security_log :password_reset
          redirect_back(fallback_location: profile_newflow_url)
        },
        failure: lambda {
          security_log :password_reset_failed
          render :change_password_form, status: 400
        }
      )
    end

    def logout
      sign_out!
      redirect_to newflow_login_path # or redirect back?
    end

    # Log in (or sign up and then log in) a user using a social (OAuth) provider
    def oauth_callback
      handle_with(
        OauthCallback,
        success: lambda {
          authentication = @handler_result.outputs.authentication
          user = @handler_result.outputs.user
          unless user.is_activated?
            # not activated means signup
            save_unverified_user(user)
            @first_name = user.first_name
            @last_name = user.last_name
            @email = @handler_result.outputs.email
            security_log(:sign_up_successful, user: user, authentication_id: authentication.id)
            # must confirm their social info on signup
            render :confirm_social_info_form and return
          end
          sign_in!(user)
          # we should perhaps create a more specific security log
          security_log(:sign_in_successful, user: user, authentication_id: authentication.id)
          redirect_back(fallback_location: profile_newflow_path)
        },
        failure: lambda {
          @email = @handler_result.outputs.email
          save_login_failed_email(@email)
          # TODO: rate-limit this
          # TODO: is this the appropriate security log?
          render :social_login_failed
        }
      )
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
          # security_log :sign_up_successful
          # security_log :authentication_created
          redirect_to signup_done_path
        },
        failure: lambda {
          render :confirm_social_info_form
        }
      )
    end

    def setup_password
      handle_with(
        SetupPassword,
        user: current_user,
        success: lambda {
          # TODO: security_log :sign_in_successful {security_log_data: {type: 'token'}} or something
          redirect_back(fallback_location: profile_newflow_url)
        },
        failure: lambda {
          # TODO: security_log :sign_in_failed or something
          render :setup_password_form
          # TODO: add an error msg to the form, if not happening already.
        }
      )
    end

    private #################

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
        redirect_to(profile_newflow_path) # TODO: should probably redirect back
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
  end
end
