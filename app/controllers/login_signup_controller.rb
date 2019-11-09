# Contains every action for login and signup
class LoginSignupController < ApplicationController
  layout 'newflow_layout'
  skip_before_action :authenticate_user!, except: [:profile_newflow]
  skip_before_action :check_if_password_expired
  fine_print_skip :general_terms_of_use, :privacy_policy,
                  except: [:profile_newflow, :verify_pin, :signup_done]

  def login_form
    # Send to profile upon login unless in the middle of authorizing an oauth app
    # in which case they'll go back to the oauth authorization path
    store_url(url: profile_newflow_url) unless params[:client_id]
  end

  def login
    handle_with(AuthenticateUser,
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
    handle_with(StudentSignup,
                contracts_required: !contracts_not_required,
                success: lambda {
                  # clear_login_state
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
        sign_in!(@handler_result.outputs.user)
        # redirect_to profile_newflow_path
        redirect_back(fallback_location: profile_newflow_path)
      },
      failure: lambda {
        redirect_to newflow_social_login_failed_path
      }
    )
  end

  def verify_pin
    handle_with(NewflowVerifyEmail,
                success: lambda {
                  sign_in!(@handler_result.outputs.user)
                  redirect_to signup_done_path
                }, failure: lambda {
                  render :confirmation_form
                })
  end

  # TODO: require a PreAuthState present in the session OR  a logged in user.
  def signup_done
    @first_name = current_user.first_name
    @email_address = current_user.email_addresses.first.value
  end

  def profile_newflow
    render layout: 'application'
  end

  def social_login_failed
    render plain: 'SOCIAL LOGIN FAILED'
  end

  def logout
    sign_out!
    redirect_to newflow_login_path
  end
end
