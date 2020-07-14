module Newflow
  class EducatorSignupController < SignupController

    include EducatorSignupHelper

    skip_forgery_protection(only: :sheerid_webhook)

    before_action(:prevent_caching, only: :sheerid_webhook)
    before_action(:restart_signup_if_missing_unverified_user, only: %i[
        educator_change_signup_email_form
        educator_change_signup_email
        educator_email_verification_form
        educator_email_verification_form_updated_email
        educator_verify_email_by_pin
      ]
    )
    before_action(:restart_signup_if_missing_incomplete_educator, only: %i[
        educator_sheerid_form
        educator_profile_form
        educator_complete_profile
      ]
    )
    before_action(:stepwise_signup_flow_triggers)

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
          user = @handler_result.outputs.user
          clear_unverified_user
          save_incomplete_educator(user)
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
      @sheerid_url = generate_sheer_id_url(user: current_incomplete_educator)
      security_log(:user_viewed_signup_form, form_name: action_name)
    end

    # SheerID makes a POST request to this endpoint when it verifies an educator
    # http://developer.sheerid.com/program-settings#webhooks
    def sheerid_webhook
      handle_with(
        EducatorSignup::SheeridWebhook,
        success: lambda {
          render(status: :ok, plain: 'Success')
        },
        failure: lambda {

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
      security_log(:user_viewed_signup_form, user: current_incomplete_educator, form_name: action_name)
    end

    def educator_complete_profile
      handle_with(
        EducatorSignup::CompleteProfile,
        user: current_incomplete_educator,
        success: lambda {
          user = @handler_result.outputs.user
          security_log(:user_updated, user: user, message: 'Completed Educator Profile')
          sign_in!(user)
          clear_incomplete_educator
          clear_unverified_user

          if @handler_result.outputs.is_educator_pending_cs_verification
            redirect_to(educator_pending_cs_verification_path)
          else
            redirect_to(signup_done_path)
          end
        },
        failure: lambda {
          @book_subjects = book_data.subjects
          @book_titles = book_data.titles
          security_log(:educator_sign_up_failed, user: current_incomplete_educator, reason: "Error in educator_complete_profile: #{@handler_result&.errors&.full_messages}")
          render :educator_profile_form
        }
      )
    end

    def educator_pending_cs_verification
      security_log(:user_viewed_signup_form, form_name: action_name)
      @email_address = current_user.email_addresses.first&.value
    end

    private #################

    def book_data
      @book_data ||= FetchBookData.new
    end

  end
end
