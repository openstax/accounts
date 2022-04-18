class SignupController < ApplicationController
  include LoginSignupHelper

  fine_print_skip :general_terms_of_use, :privacy_policy

  before_action(:authenticate_user!, only: :signup_done)

  before_action(:restart_signup_if_missing_verified_user, only: %i[
      change_signup_email_form
      change_signup_email_post
      email_verification_form
      email_verification_form_updated_email
      verify_email_by_pin
    ]
  )

  def welcome
    redirect_back if signed_in?
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
      is_BRI_book:          is_BRI_book_adopter?,
      success:              lambda {
        save_unverified_user(@handler_result.outputs.user.id)
        security_log(:user_began_signup, { user: @handler_result.outputs.user })
        clear_cache_BRI_marketing
        redirect_to verify_email_by_pin_form_path
      },
      failure:              lambda {
        security_log(:user_signup_failed, { reason: @handler_result.errors.map(&:code), email: @handler_result.outputs.email })
        render :signup_form
      }
    )
  end

  def verify_email_by_pin_form
    @first_name = unverified_user.first_name
    @email = unverified_user.email_addresses.first.value
    render :email_verification_form
  end

  def verify_email_by_pin_post
    handle_with(
      VerifyEmailByPin,
      email_address: unverified_user.email_addresses.first,
      success:       lambda {
        clear_signup_state
        user = @handler_result.outputs.user
        sign_in!(user)
        if user.role == :student
          security_log(:student_verified_email, { user: user, message: "Student verified email." })
          redirect_to signup_done_path
        elsif user.role == :instructor
          security_log(:educator_verified_email, { user: user, message: "Educator verified email." })
          redirect_to sheerid_form_path
        end
      },
      failure:       lambda {
        @first_name = unverified_user.first_name
        @email      = unverified_user.email_addresses.first.value
        security_log(:user_verify_email_failed, email: @email)
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

        if user.student?
          security_log(:student_verified_email, {user: user, message: "Student verified email."})
          redirect_to signup_done_path
        else
          security_log(:educator_verified_email, {user: user, message: "Educator verified email."})
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
        redirect_to change_signup_email_form_complete
      },
      failure: lambda {
        @email = unverified_user.email_addresses.first.value
        render :change_signup_email_form
      }
    )
  end

  def change_signup_email_form_complete
    render :email_verification_form_updated
  end

  def signup_done
    redirect_back if current_user.is_tutor_user?

    security_log(:user_viewed_signup_form, form_name: action_name)
    @first_name = current_user.first_name
    @email_address = current_user.email_addresses.first&.value
  end

end
