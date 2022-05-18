class SignupController < ApplicationController
  include LoginSignupHelper

  before_action(:authenticate_user!, only: :signup_done)
  before_action(:total_steps, except: [:welcome])

  def welcome
    redirect_back(fallback_location: profile_path) if signed_in?
  end

  def signup_form
    @selected_signup_role = params[:role]
    # make sure they are using one of the approved roles to signup
    if %w[educator student].include? @selected_signup_role
      render :signup_form
    else
      head(:not_found)
    end
  end

  def signup_post
    handle_with(
      SignupForm,
      contracts_required:   !contracts_not_required,
      client_app:           get_client_app,
      is_bri_book:          is_bri_book_adopter?,
      success:              lambda {
        save_unverified_user(@handler_result.outputs.user.id)
        security_log(:user_began_signup, { user: @handler_result.outputs.user })
        clear_cache_bri_marketing
        redirect_to verify_email_by_pin_form_path
      },
      failure:              lambda {
        security_log(:user_signup_failed,
{ reason: @handler_result.errors.map(&:code), email: @handler_result.outputs.email })
        render :signup_form
      }
    )
  end

  def verify_email_by_pin_form
    render :email_verification_form
  end

  def verify_email_by_pin_post
    handle_with(
      VerifyEmailByPin,
      email_address: unverified_user.email_addresses.first,
      success:       lambda {
        user = @handler_result.outputs.user
        sign_in!(user)
        security_log(:contact_info_confirmed_by_pin,
                     { user: user, email_address: unverified_user.email_addresses.first.value })

        if user.student?
          redirect_to signup_done_path
        else # instructor/educator
          redirect_to sheerid_form_path
        end
      },
      failure: lambda {
        security_log(:contact_info_confirmation_by_pin_failed, email: unverified_user.email_addresses.first)
        render :email_verification_form
      }
    )
  end

  def verify_email_by_code
    handle_with(
      VerifyEmailByCode,
      success: lambda {
        clear_signup_state
        user = @handler_result.outputs.user
        sign_in!(user)
        security_log(:contact_info_confirmed_by_code, { user: user, email_address: user.email_addresses.first.value })

        if user.student?
          redirect_to signup_done_path
        else # instructor/educator
          redirect_to sheerid_form_path
        end
      },
      failure: lambda {
        redirect_to signup_path
      }
    )
  end

  def change_signup_email_form
    @email = unverified_user.email_addresses.first.value
    render :change_signup_email_form
  end

  def change_signup_email_post
    handle_with(
      ChangeSignupEmail,
      user:    unverified_user,
      success: lambda {
        redirect_to verify_email_by_pin_form_path and return
      },
      failure: lambda {
        @email = unverified_user.email_addresses.first.value
        render :change_signup_email_form and return
      }
    )
  end

  def signup_done
    security_log(:sign_up_successful, form_name: action_name)
    redirect_back(fallback_location: :signup_done) if current_user.is_tutor_user?
  end

  private

  def total_steps
    @total_steps ||= if params[:role]
                       params[:role] == 'student' ? 2 : 4
                     elsif !current_user.is_anonymous?
                      current_user&.role == 'student' ? 2 : 4
                     end
  end
end
