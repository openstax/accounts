module Newflow
  # The "lifelong learner" signup path: the quiet escape-hatch link off role
  # selection for people who just want to read/save books, with no course or
  # school affiliation. Mirrors StudentSignupController's shape (same lev
  # handlers/routines, same session-based signup-in-progress plumbing) but
  # collects only an email + password, and lands on a dedicated welcome/home
  # screen instead of the generic signup_done page.
  class LearnerSignupController < SignupController
    before_action(:restart_signup_if_missing_unverified_user, only: %i[
        learner_change_signup_email_form
        learner_change_signup_email
        learner_email_verification_form
        learner_email_verification_form_updated_email
        learner_verify_email_by_pin
      ]
    )
    before_action(:newflow_authenticate_user!, only: :learner_welcome)

    def learner_signup_form
    end

    def learner_signup
      if verify_recaptcha_with_fallback
        handle_with(
          LearnerSignup::SignupForm,
          contracts_required: !contracts_not_required,
          client_app: get_client_app,
          success: lambda {
            user = @handler_result.outputs.user
            save_unverified_user(user.id)
            security_log(:self_learner_signed_up, user: user)
            log_posthog(user, "self_learner_started_signup", { client_app: get_client_app&.name })
            redirect_to learner_email_verification_form_path
          },
          failure: lambda {
            email = @handler_result.outputs.email
            error_codes = @handler_result.errors.map(&:code)
            security_log(:self_learner_sign_up_failed, { reason: error_codes, email: email })
            render :learner_signup_form
          }
        )
      else
        render :learner_signup_form
      end
    end

    def learner_change_signup_email_form
      @email = unverified_user.email_addresses.first.value
    end

    def learner_change_signup_email
      if verify_recaptcha_with_fallback
        handle_with(
          ChangeSignupEmail,
          user: unverified_user,
          success: lambda {
            redirect_to learner_email_verification_form_updated_email_path
          },
          failure: lambda {
            @email = unverified_user.email_addresses.first.value
            render :learner_change_signup_email_form
          }
        )
      else
        @email = unverified_user.email_addresses.first.value
        render :learner_change_signup_email_form
      end
    end

    def learner_email_verification_form
      @email = unverified_user.email_addresses.first.value
    end

    def learner_email_verification_form_updated_email
      @email = unverified_user.email_addresses.first.value
    end

    def learner_verify_email_by_pin
      handle_with(
        LearnerSignup::VerifyEmailByPin,
        email_address: unverified_user.email_addresses.first,
        success: lambda {
          clear_signup_state
          user = @handler_result.outputs.user
          sign_in!(user)
          security_log(:self_learner_verified_email)
          log_posthog(user, "self_learner_verified_email")
          redirect_to(learner_welcome_path)
        },
        failure: lambda {
          @email = unverified_user.email_addresses.first.value
          security_log(:self_learner_verify_email_failed, email: @email)
          render(:learner_email_verification_form)
        }
      )
    end

    def learner_welcome
      @first_name = current_user.casual_name
    end
  end
end
