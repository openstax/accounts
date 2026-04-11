module Newflow
  class StudentSignupController < SignupController
    before_action(:restart_signup_if_missing_unverified_user, only: %i[
        student_change_signup_email_form
        student_change_signup_email
        student_email_verification_form
        student_email_verification_form_updated_email
        student_verify_email_by_pin
      ]
    )

    def student_signup
      if verify_recaptcha_with_fallback
        handle_with(
          StudentSignup::SignupForm,
          contracts_required: !contracts_not_required,
          client_app: get_client_app,
          success: lambda {
            user = @handler_result.outputs.user
            save_unverified_user(user.id)
            log_data = { user: user }
            if stored_url.present?
              log_data[:redirect] = stored_url
            end
            security_log(:student_signed_up, log_data)
            log_posthog(user, "student_started_signup", { client_app: get_client_app&.name })
            redirect_to student_email_verification_form_path
          },
          failure: lambda {
            email = @handler_result.outputs.email
            error_codes = @handler_result.errors.map(&:code)
            security_log(:student_sign_up_failed, { reason: error_codes, email: email })
            render :student_signup_form
          }
        )
      else
        render :student_signup_form
      end
    end

    def student_change_signup_email_form
      @email = unverified_user.email_addresses.first.value
    end

    def student_change_signup_email
      if verify_recaptcha_with_fallback
        handle_with(
          ChangeSignupEmail,
          user: unverified_user,
          success: lambda {
            redirect_to student_email_verification_form_updated_email_path
          },
          failure: lambda {
            @email = unverified_user.email_addresses.first.value
            render :student_change_signup_email_form
          }
        )
      else
        @email = unverified_user.email_addresses.first.value
        render :student_change_signup_email_form
      end
    end

    def student_email_verification_form
      @first_name = unverified_user.first_name
      @email = unverified_user.email_addresses.first.value
    end

    def student_email_verification_form_updated_email
      @email = unverified_user.email_addresses.first.value
    end

    def student_verify_email_by_pin
      handle_with(
        StudentSignup::VerifyEmailByPin,
        email_address: unverified_user.email_addresses.first,
        success: lambda {
          clear_signup_state
          user = @handler_result.outputs.user
          sign_in!(user)
          security_log(:student_verified_email)
          log_posthog(user, "student_verified_email")
          redirect_to(signup_done_path)
        },
        failure: lambda {
          @first_name = unverified_user.first_name
          @email = unverified_user.email_addresses.first.value
          security_log(:student_verify_email_failed, email: @email)
          render(:email_verification_form)
        }
      )
    end
  end
end
