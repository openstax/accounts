module Newflow
  class EducatorSignupController < SignupController
    layout 'newflow_layout'

    skip_before_action :restart_signup_if_missing_unverified_user, only: [
      :educator_signup_form, :educator_signup, :educator_sheerid_form,
      :educator_change_signup_email_form, :educator_change_signup_email,
      :educator_profile_form
    ]

    before_action :newflow_authenticate_user!, only: [
      :educator_sheerid_form, :educator_profile_form, :educator_complete_profile
    ]

    def educator_signup
      handle_with(
        EducatorSignup,
        contracts_required: !contracts_not_required,
        client_app: get_client_app,
        success: lambda {
          save_unverified_user(@handler_result.outputs.user)
          security_log(:educator_signed_up, { user: @handler_result.outputs.user })
          redirect_to(educator_email_verification_form_path)
        },
        failure: lambda {
          email = @handler_result.outputs.email
          error_codes = @handler_result.errors.map(&:code)
          security_log(:educator_sign_up_failed, { reason: error_codes, email: email })
          render :educator_signup_form
        }
      )
    end

    def educator_change_signup_email_form
      @email = unverified_user.email_addresses.first.value
    end

    def educator_change_signup_email
      handle_with(
        ChangeSignupEmail,
        user: unverified_user,
        success: lambda {
          redirect_to(educator_email_verification_form_updated_email_path)
        },
        failure: lambda {
          @email = unverified_user.email_addresses.first.value
          render(:educator_change_signup_email_form)
        }
      )
    end

    def educator_email_verification_form
      @total_steps = 4
      @first_name = unverified_user.first_name
      @email = unverified_user.email_addresses.first.value
    end

    def educator_email_verification_form_updated_email
      @total_steps = 4
      @email = unverified_user.email_addresses.first.value
    end

    def educator_verify_email_by_pin
      handle_with(
        VerifyEmailByPin,
        email_address: unverified_user.email_addresses.first,
        success: lambda {
          clear_newflow_state
          user = @handler_result.outputs.user
          sign_in!(user)
          security_log(:educator_verified_email)

          redirect_to(educator_sheerid_form_path)
        },
        failure: lambda {
          @total_steps = 4
          @first_name = unverified_user.first_name
          @email = unverified_user.email_addresses.first.value
          # TODO: we might want to change this security log for a sentry error instead
          security_log(:educator_verify_email_failed, email: @email)
          render(:educator_email_verification_form)
        }
      )
    end

    def educator_sheerid_form
      @sheerid_url = generate_sheer_id_url(user: current_user)
      security_log(:user_viewed_sheer_id_form)
      # Practically, this allows the sheerID success flow to be environment-agnostic
      session[:after_faculty_verified] = educator_profile_form_url
    end

    def educator_profile_form
      @book_subjects = book_data.subjects
      @book_titles = book_data.titles
    end

    def educator_complete_profile
      handle_with(
        EducatorCompleteProfile,
        success: lambda {
          security_log(:completed_educator_profile)
          redirect_to(signup_done_path)
        },
        failure: lambda {
          @book_subjects = book_data.subjects
          @book_titles = book_data.titles
          render :educator_profile_form
        }
      )
    end

    protected ###############

    def book_data
      @book_data ||= FetchBookData.new
    end
  end
end
