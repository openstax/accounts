class SignupController < ApplicationController

  include LoginSignupHelper

  skip_before_action :authenticate_user!, except: :signup_done
  before_action :skip_signup_done_for_tutor_users, only: :signup_done
  before_action :total_steps, except: :welcome
  before_action :return_to_signup_if_not_signed_in, except: [:welcome, :signup_form, :signup_post]

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
      # TODO: what is all this stuff getting set?
      contracts_required: !contracts_not_required,
      client_app: get_client_app,
      is_bri_book: is_bri_book_adopter?,
      success: lambda {
        user = @handler_result.outputs.user
        security_log(:user_viewed_signup_form, { user: user })
        clear_cache_bri_marketing

        user.faculty_status = 'needs_email_verified'
        user.save!
        sign_in!(user)
        redirect_to verify_email_by_pin_form_path and return
      },
      failure: lambda {
        @errors = @handler_result.errors
        security_log(:sign_up_failed, { reason: @handler_result.errors.map(&:code)})
        render(:signup_form, params: { role: @selected_signup_role }) and return
      }
    )
  end

  def verify_email_by_pin_form
    render :email_verification_form
  end

  def verify_email_by_pin_post
    handle_with(
      VerifyEmailByPin,
      email_address: current_user.email_addresses.first,
      success: lambda {
        user = @handler_result.outputs.user
        sign_in!(user)
        security_log(:contact_info_confirmed_by_pin,
                     { user: user, email_address: current_user.email_addresses.first.value })

        if user.student?
          redirect_to signup_done_path
        else
          # instructor/educator
          redirect_to sheerid_form_path
        end
      },
      failure: lambda {
        security_log(:contact_info_confirmation_by_pin_failed, email: current_user.email_addresses.first)
        render :email_verification_form
      }
    )
  end

  def verify_email_by_code
    handle_with(
      VerifyEmailByCode,
      success: lambda {
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

  def change_signup_email_form; end

  def change_signup_email_post
    handle_with(
      ChangeSignupEmail,
      user: current_user,
      success: lambda {
        redirect_to verify_email_by_pin_form_path and return
      },
      failure: lambda {
        @email = current_user.email_addresses.first.value
        render :change_signup_email_form and return
      }
    )
  end

  def check_your_email; end

  def signup_done
    security_log(:sign_up_successful, form_name: action_name)
    if current_user.source_application&.name&.downcase&.include?('tutor')
      redirect_back
    else
      redirect_to(profile_path)
    end
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
    return unless current_user.source_application&.name&.downcase&.include?('tutor')
    redirect_back(fallback_location: signup_done_path)
  end

  def return_to_signup_if_not_signed_in
    if current_user.is_anonymous? || !session[:signing_up_user]
      redirect_to(signup_path)
    end
  end
end
