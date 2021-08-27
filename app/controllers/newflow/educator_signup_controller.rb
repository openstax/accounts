module Newflow
  class EducatorSignupController < SignupController

    include EducatorSignupHelper

    skip_forgery_protection(only: :sheerid_webhook)

    before_action(:prevent_caching, only: :sheerid_webhook)
    before_action(:exit_newflow_signup_if_logged_in, only: :educator_signup_form)
    before_action(:restart_signup_if_missing_unverified_user, only: %i[
        educator_change_signup_email_form
        educator_change_signup_email
        educator_email_verification_form
        educator_email_verification_form_updated_email
        educator_verify_email_by_pin
      ]
    )
    before_action(:newflow_authenticate_user!, only: %i[
        educator_sheerid_form
        educator_profile_form
        educator_complete_profile
        educator_pending_cs_verification
        educator_cs_verification_form
        educator_cs_verification_request
      ]
    )
    before_action(:store_if_sheerid_is_unviable_for_user, only: :educator_profile_form)
    before_action(:store_sheerid_verification_for_user, only: :educator_profile_form)
    before_action(:exit_signup_if_steps_complete, only: %i[
        educator_sheerid_form
        educator_profile_form
        educator_cs_verification_form
      ]
    )

    def educator_signup
      handle_with(
        EducatorSignup::SignupForm,
        contracts_required: !contracts_not_required,
        client_app: get_client_app,
        user_from_signed_params: session[:user_from_signed_params],
        is_BRI_book: is_BRI_book_adopter?,
        success: lambda {
          save_unverified_user(@handler_result.outputs.user.id)
          security_log(:educator_signed_up, { user: @handler_result.outputs.user, user_state: @handler_result.outputs.user.attributes.delete_if { |k,v| v.nil? } })
          clear_cache_BRI_marketing
          redirect_to(educator_email_verification_form_path)
        },
        failure: lambda {
          security_log(:educator_sign_up_failed, { reason: @handler_result.errors.map(&:code), email: @handler_result.outputs.email })
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
          @email = unverified_user.email_addresses.first.value
          clear_unverified_user
          sign_in!(@handler_result.outputs.user)
          security_log(:educator_verified_email, email:@email)
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
      security_log(:user_viewed_signup_form, { form_name: action_name, user: current_user, user_state: current_user.attributes.delete_if { |k,v| v.nil? } })
    end

    # SheerID makes a POST request to this endpoint when it verifies an educator
    # http://developer.sheerid.com/program-settings#webhooks
    def sheerid_webhook
      handle_with(
        EducatorSignup::SheeridWebhook,
        success: lambda {
          security_log(:user_updated_using_sheerid_data, { data: @handler_result, user: current_user, user_state: current_user.attributes.delete_if { |k,v| v.nil? } })
          render(status: :ok, plain: 'Success')
        },
        failure: lambda {
          Sentry.capture_message(
            'SheerID webhook FAILED',
            extra: {
              verificationid: params['verificationId'],
              reason: @handler_result.errors.first.code
            },
            user: { verificationid: params['verificationId'] }
          )
          render(status: :unprocessable_entity)
        }
      )
    end

    def educator_profile_form
      @book_titles = book_data.titles
      security_log(:user_viewed_signup_form, user: current_user, form_name: action_name)
    end

    def educator_complete_profile
      handle_with(
        EducatorSignup::CompleteProfile,
        user: current_user,
        success: lambda {
          user = @handler_result.outputs.user
          security_log(:user_updated, { user: user, user_state: user.attributes.delete_if { |k,v| v.nil? } })
          clear_incomplete_educator

          if user.is_educator_pending_cs_verification?
            redirect_to(educator_pending_cs_verification_path)
          else
            redirect_to(signup_done_path)
          end
        },
        failure: lambda {
          @book_titles = book_data.titles
          security_log(:educator_sign_up_failed, user: current_user, reason: "Error in #{action_name}: #{@handler_result&.errors&.full_messages}")
          render :educator_profile_form
        }
      )
    end

    def educator_cs_verification_form
      @book_titles = book_data.titles
      security_log(:user_viewed_signup_form, { form_name: action_name, user: current_user, user_state: current_user.attributes.delete_if { |k,v| v.nil? } })
    end

    def educator_pending_cs_verification
      security_log(:user_viewed_signup_form, { form_name: action_name, user: current_user, user_state: current_user.attributes.delete_if { |k,v| v.nil? } })
      @email_address = current_user.email_addresses.last&.value
    end

    def educator_cs_verification_request
      handle_with(
        EducatorSignup::CsVerificationRequest,
        user: current_user,
        success: lambda {
          security_log(:requested_manual_cs_verification, { form_name: action_name, user: current_user, user_state: current_user.attributes.delete_if { |k,v| v.nil? } })
          redirect_to(educator_pending_cs_verification_path)
        },
        failure: lambda {
          @book_titles = book_data.titles
          security_log(:educator_sign_up_failed, user: current_user, reason: "Error in #{action_name}: #{@handler_result&.errors&.full_messages}")
          render :educator_cs_verification_form
        }
      )
    end

    private #################

    def store_if_sheerid_is_unviable_for_user
      if is_school_not_supported_by_sheerid? || is_country_not_supported_by_sheerid?
        current_user.update!(is_sheerid_unviable: true)
        security_log(:user_updated, message: 'user not viable for sheerid', user: current_user)
      end
    end

    def store_sheerid_verification_for_user
      if sheerid_provided_verification_id_param.present? && current_user.sheerid_verification_id.blank?
        current_user.update!(sheerid_verification_id: sheerid_provided_verification_id_param)
        security_log(:user_updated, message: "updated sheerid_verification_id to #{sheerid_provided_verification_id_param}", user: current_user)
      end
    end

    def exit_signup_if_steps_complete
      return if !current_user.is_newflow?

      case true
      when current_user.is_educator_pending_cs_verification && current_user.pending_faculty?
        security_log(:educator_signed_up, message: 'User pending CS verification and pending verification')
        redirect_to(educator_pending_cs_verification_path)
      when current_user.is_educator_pending_cs_verification && !current_user.pending_faculty?
        security_log(:educator_signed_up, message: 'User pending CS verification and not pending verification')
        redirect_back(fallback_location: profile_newflow_path)
      when action_name == 'educator_sheerid_form' && current_user.step_3_complete?
        security_log(:educator_signed_up, message: 'User redirected to finish profile information')
        redirect_to(educator_profile_form_path)
      when action_name == 'educator_profile_form' && current_user.is_profile_complete?
        security_log(:educator_signed_up, message: 'User completed signup, sending to profile.')
        redirect_to(profile_newflow_path)
      end
    end

    def book_data
      @book_data ||= FetchBookData.new
    end

  end
end
