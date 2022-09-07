class SignupController < ApplicationController

  include LoginSignupHelper

  skip_before_action :authenticate_user!, except: :signup_done
  before_action :skip_signup_done_for_tutor_users, only: :signup_done
  before_action :total_steps, except: :welcome
  before_action(:return_to_signup_if_not_signed_in, only: %i[
      change_signup_email_form
      change_signup_email
      verify_email_by_code
      verify_email_by_pin_form
      verify_email_by_pin_post
    ]
  )

  def welcome
    redirect_back(fallback_location: profile_path) if signed_in?
  end

  def signup_form
    @selected_signup_role = params[:role].to_sym
    @errors = params[:errors]
    # make sure they are using one of the approved roles to signup
    if [:educator, :student].include? @selected_signup_role
      # Educator is what is displayed on accounts, instructor is the internal name for this role
      if @selected_signup_role == :educator
        @selected_signup_role = :instructor
      end

      render :signup_form
    else
      head(:not_found)
    end
  end

  def signup_post
    handle_with(
      SignupForm,
      # TODO: what is all this stuff getting set for?
      contracts_required: !contracts_not_required,
      client_app: get_client_app,
      is_bri_book: is_bri_book_adopter?,
      success: lambda {
        @signing_up_user = @handler_result.outputs.user
        session[:signing_up_user] = @signing_up_user

        security_log(:user_viewed_signup_form, { user: @signing_up_user })
        clear_cache_bri_marketing

        @signing_up_user.faculty_status = 'needs_email_verified'
        @signing_up_user.save!
        sign_in!(@signing_up_user)
        session[:signing_up_user] = @signing_up_user
        redirect_to verify_email_by_pin_form_path and return
      },
      failure: lambda {
        @errors = @handler_result.errors
        security_log(:sign_up_failed, { reason: @errors.map(&:code)})
        render(:signup_form, params: { role: @selected_signup_role }) and return
      }
    )
  end

  def verify_email_by_pin_form
    @signing_up_user ||= current_user.is_anonymous? ? session[:signing_up_user] : current_user
    render :email_verification_form
  end

  def verify_email_by_pin_post
    @signing_up_user ||= current_user.is_anonymous? ? session[:signing_up_user] : current_user
    handle_with(
      VerifyEmailByPin,
      email_address: @signing_up_user.email_addresses.first,
      success: lambda {
        @signing_up_user = @handler_result.outputs.user
        sign_in!(@signing_up_user)
        security_log(:contact_info_confirmed_by_pin,
                     { user: @signing_up_user, email_address: @signing_up_user.email_addresses.first.value })

        if @signing_up_user.student?
          redirect_to signup_done_path
        else
          # instructor/educator
          redirect_to sheerid_form_path
        end
      },
      failure: lambda {
        security_log(:contact_info_confirmation_by_pin_failed, email: @signing_up_user.email_addresses.first)
        render :email_verification_form
      }
    )
  end

  def verify_email_by_code
    @signing_up_user ||= current_user.is_anonymous? ? session[:signing_up_user] : current_user
    handle_with(
      VerifyEmailByCode,
      success: lambda {
        @signing_up_user = @handler_result.outputs.user
        security_log(:contact_info_confirmed_by_code, { user: user, email_address: @signing_up_user[:email][:value] })

        if @signing_up_user.student?
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
    @signing_up_user ||= current_user.is_anonymous? ? session[:signing_up_user] : current_user
    render :change_signup_email_form
  end

  def change_signup_email_post
    @signing_up_user ||= current_user.is_anonymous? ? session[:signing_up_user] : current_user
    handle_with(
      ChangeSignupEmail,
      user: @signing_up_user,
      success: lambda {
        @email = @signing_up_user.email_addresses.first.value
        redirect_to verify_email_by_pin_form_path and return
      },
      failure: lambda {
        @email = @signing_up_user.email_addresses.first.value
        render :change_signup_email_form and return
      }
    )
  end

  def check_your_email
    @signing_up_user ||= current_user.is_anonymous? ? session[:signing_up_user] : current_user
  end

  def signup_done
    @signing_up_user ||= current_user.is_anonymous? ? session[:signing_up_user] : current_user
    security_log(:sign_up_successful, form_name: action_name)
    redirect_to(profile_path)
  end

  private

  def skip_to_student_sign_up
    if %w[signup student_signup].include?(request.params[:go])
      redirect_to signup_path(role: 'student')
    end
  end

  def total_steps
    unless current_user.is_anonymous?
      @total_steps ||= params[:role] == 'student' ? 2 : 4
     end
  end

  def skip_signup_done_for_tutor_users
    return unless @signing_up_user.source_application&.name&.downcase&.include?('tutor')
    redirect_back(fallback_location: signup_done_path)
  end

  def return_to_signup_if_not_signed_in
    if current_user.is_anonymous? || @signing_up_user[:role].nil?
      redirect_to(signup_path)
    end
  end
end
