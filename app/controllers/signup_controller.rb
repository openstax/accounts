class SignupController < BaseController

  include LoginSignupHelper

  skip_before_action :authenticate_user!, except: :signup_done

  before_action(:restart_signup_if_missing_unverified_user, only: %i[
      change_signup_email_form
      change_signup_email
      verify_email_by_code
      verify_email_by_pin_form
      verify_email_by_pin_post
    ]
  )

  before_action(:exit_signup_if_logged_in, only: :welcome)
  before_action(:skip_signup_done_for_tutor_users, only: :signup_done)
  before_action(:total_steps, except: [:welcome])

  def welcome
    redirect_back(fallback_location: profile_path) if signed_in?
  end

  def signup_form
    @selected_signup_role = params[:role]
    @errors = params[:errors]
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
      contracts_required: !contracts_not_required,
      client_app: get_client_app,
      is_bri_book: is_bri_book_adopter?,
      success: lambda {
        save_unverified_user(@handler_result.outputs.user.id)
        security_log(:user_viewed_signup_form, { user: @handler_result.outputs.user })
        clear_cache_bri_marketing
        redirect_to verify_email_by_pin_form_path and return
      },
      failure: lambda {
        security_log(:sign_up_failed,
                     { reason: @handler_result.errors.map(&:code), email: @handler_result.outputs.email })
        render :signup_form and return
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
      success: lambda {
        user = @handler_result.outputs.user
        sign_in!(user)
        security_log(:contact_info_confirmed_by_pin,
                     { user: user, email_address: unverified_user.email_addresses.first.value })

        if user.student?
          redirect_to signup_done_path
        else
          # instructor/educator
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
        else
          # instructor/educator
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
      user: unverified_user,
      success: lambda {
        redirect_to verify_email_by_pin_form_path and return
      },
      failure: lambda {
        @email = unverified_user.email_addresses.first.value
        render :change_signup_email_form and return
      }
    )
  end

  def check_your_email; end

  def signup_done
    if current_user.receive_newsletter? && current_user.role == 'student'
      CreateSalesforceLead.perform_later(user_id: current_user.id)
    end

    security_log(:sign_up_successful, form_name: action_name)
    redirect_back if current_user.is_tutor_user?
  end

  private

  def skip_to_student_sign_up
    if %w[signup student_signup].include?(request.params[:go])
      redirect_to signup_path(role: 'student')
    end
  end

  def total_steps
    @total_steps ||= if params[:role]
       params[:role] == 'student' ? 2 : 4
     elsif !current_user.is_anonymous?
       current_user&.role == 'student' ? 2 : 4
     end
  end

  def skip_signup_done_for_tutor_users
    return unless current_user.is_tutor_user?

    redirect_back(fallback_location: signup_done_path)
  end

  def exit_signup_if_logged_in
    if signed_in?
      redirect_back(fallback_location: profile_path(request.query_parameters))
    end
  end
end
