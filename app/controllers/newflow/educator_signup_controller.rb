module Newflow
  class EducatorSignupController < SignupController
    skip_forgery_protection(only: :sheerid_webhook)

    skip_before_action :restart_signup_if_missing_unverified_user, only: [
      :educator_signup_form, :educator_signup, :educator_sheerid_form,
      :educator_change_signup_email_form, :educator_change_signup_email,
      :educator_profile_form, :educator_complete_profile, :sheerid_webhook
    ]

    before_action :newflow_authenticate_user!, only: [
      :educator_sheerid_form, :educator_profile_form, :educator_complete_profile
    ]
    before_action :prevent_caching, only: :sheerid_webhook

    def educator_signup
      handle_with(
        EducatorSignup::SignupForm,
        contracts_required: !contracts_not_required,
        client_app: get_client_app,
        user_from_signed_params: session[:user_from_signed_params],
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
      @total_steps = 4
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
        EducatorSignup::VerifyEmailByPin,
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
      security_log(:user_viewed_signup_form, form_name: 'educator_sheerid_form')
    end

    # SheerID makes a POST request to this endpoint when it verifies an educator
    # http://developer.sheerid.com/program-settings#webhooks
    def sheerid_webhook
      handle_with(
        EducatorSignup::SheeridWebhook,
        success: lambda {
          Rails.logger.info("bryan_sheerid_verify. Reached sheerid_webhook success lambda. verification_id: #{@handler_result.outputs.verification_id}")
          render(status: :ok, plain: 'Success')
        },
        failure: lambda {
          Rails.logger.warn("bryan_sheerid_verify. Reached sheerid_webhook failure lambda. verification_id: #{@handler_result.outputs.verification_id}.")

          Raven.capture_message(
            'SheerID webhook is failing!',
            extra: {
              request_ip: request.remote_ip,
              verificationid: params['verificationId'],
              reason: @handler_result.errors.first.code
            }
          )
          render(status: :unprocessable_entity)
        }
      )
    end

    def educator_profile_form
      @book_subjects = book_data.subjects
      @book_titles = book_data.titles
      security_log(:user_viewed_signup_form, form_name: 'educator_profile_form')
    end

    def educator_complete_profile
      handle_with(
        EducatorSignup::CompleteProfile,
        success: lambda {
          security_log(:user_updated, message: 'Completed Educator Profile')
          redirect_to(signup_done_path)
        },
        failure: lambda {
          @book_subjects = book_data.subjects
          @book_titles = book_data.titles
          security_log(:educator_sign_up_failed, reason: "Error in educator_complete_profile: #{@handler_result&.errors&.full_messages}")
          render :educator_profile_form
        }
      )
    end

    private #################

    def book_data
      @book_data ||= FetchBookData.new
    end
  end
end
