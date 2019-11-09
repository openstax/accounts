# Contains every action for login and signup
class LoginSignupController < ApplicationController
  layout 'newflow_layout'
  # before_action :exit_if_logged_in, only: [:login_form, :signup_form]
  skip_before_action :authenticate_user!, except: [:profile_newflow]
  skip_before_action :check_if_password_expired
  fine_print_skip :general_terms_of_use, :privacy_policy,
                  except: [:profile_newflow, :verify_pin, :signup_done]

  def login_form
    # Send to profile upon login unless in the middle of authorizing an oauth app
    # in which case they'll go back to the oauth authorization path
    # TODO: actually, I don't think I want to do this. Will have to test with tutor.
    store_url(url: profile_newflow_url) unless params[:client_id]
  end

  def login
    handle_with(
      AuthenticateUser,
      success: lambda {
        sign_in!(@handler_result.outputs.user)
        redirect_back(fallback_location: profile_newflow_url)
      },
      failure: lambda {
        security_log :login_not_found, tried: @handler_result.outputs.email
        render :login_form
      })
  end

  def signup
    handle_with(
      StudentSignup,
      contracts_required: !contracts_not_required,
      success: lambda {
        save_pre_auth_state(@handler_result.outputs.pre_auth_state)
        redirect_to confirmation_form_path
      }, failure: lambda {
        render :signup_form
      })
  end

  # Log in (or sign up and then log in) a user using a social (OAuth) provider
  def oauth_callback
    handle_with(
      OauthCallback,
      success: lambda {
        user = @handler_result.outputs.user
        unless user.is_activated?
          save_pre_auth_state(@handler_result.outputs.pre_auth_state)
          @pre_auth_state = pre_auth_state
          render :confirm_social_info and return
        end
        sign_in!(user)
        redirect_back(fallback_location: profile_newflow_path)
      },
      failure: lambda {
        @email = @handler_result.outputs.email
        # TODO: rate-limit this
        # TODO: create a security log
        security_log :login_not_found, tried: @handler_result.outputs.email
        render :social_login_failed
      }
    )
  end

  def confirm_oauth_info
    handle_with(
      ConfirmOauthInfo,
      pre_auth_state: pre_auth_state,
      contracts_required: !contracts_not_required,
      success: lambda {
        clear_pre_auth_state
        sign_in!(@handler_result.outputs.user)
        redirect_back(fallback_location: profile_newflow_url)
      },
      failure: lambda {
        render :confirm_social_info
      }
    )
  end

  def verify_pin
    handle_with(
      NewflowVerifyEmail,
      success: lambda {
        sign_in!(@handler_result.outputs.user)
        redirect_to signup_done_path
      },
      failure: lambda {
        render :confirmation_form
      })
  end

  # TODO: require a PreAuthState present in the session OR a logged in user.
  def signup_done
    @first_name = current_user.first_name
    @email_address = current_user.email_addresses.first.value
  end

  def profile_newflow
    render layout: 'application'
  end

  def social_login_failed
    # TODO: rate-limit this
    # TODO: create a security log
    fallback_email = current_user&.email unless is_real_production_site? # for testing purposes
    @email ||= fallback_email
  end

  def send_password_setup_instructions
    # TODO: rate-limit this
    @email_address = params[:send_instructions][:email]
    email = EmailAddress.verified.find_by(value: @email_address)
    # TODO: I may wanna raise an exception if there's no verified email found
    return unless email && (user = email.user)

    user.refresh_login_token
    user.save
    NewflowMailer.newflow_setup_password(user: email.user, email: @email_address).deliver_later
    # TODO: create a security log
    render :check_your_email
  end

  def logout
    sign_out!
    redirect_to newflow_login_path
  end

  # private ###################

  # def exit_if_logged_in
  #   store_url(url: profile_newflow_path)
  #   redirect_back(fallback_location: profile_newflow_path) if signed_in?
  # end
end
