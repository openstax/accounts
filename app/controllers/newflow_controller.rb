class NewflowController < ApplicationController
  layout 'newflow_layout'
  skip_before_action :authenticate_user!, except: [:profile_newflow]
  skip_before_action :check_if_password_expired
  fine_print_skip :general_terms_of_use, :privacy_policy

  def login
    handle_with(AuthenticateUser,
      success: -> {
        sign_in!(@handler_result.outputs.user)
        redirect_to profile_newflow_path
      },
      failure: -> {
        security_log :login_not_found, tried: @handler_result.outputs.email
        render :login_form
      }
    )
  end

  def signup
    handle_with(NewflowStudentSignup,
      contracts_required: !contracts_not_required,
      success: -> {
        # clear_login_state
        save_pre_auth_state(@handler_result.outputs.pre_auth_state)
        redirect_to confirmation_form_path
      }, failure: -> {
        render :signup_form
      }
    )
  end

  def oauth_callback
    handle_with(
      NewflowSocialCallback,
      success: -> {
        sign_in!(@handler_result.outputs[:user])
        redirect_to profile_newflow_path
      },
      failure: -> {
        redirect_to newflow_login_failed_path
      }
    )
  end

  def verify_pin
    handle_with(NewflowVerifyEmail,
      success: -> {
        sign_in!(@handler_result.outputs.user)
        redirect_to signup_done_path
      }, failure: -> {
        render :confirmation_form
      }
    )
  end

  def signup_done
    @first_name = current_user.first_name
    @email_address = current_user.email_addresses.first.value
  end

  def profile_newflow
    render layout: 'application'
  end

  def login_failed
    render plain: 'LOGIN FAILED'
  end

  def logout
    sign_out!
    redirect_to newflow_login_path
  end
end
