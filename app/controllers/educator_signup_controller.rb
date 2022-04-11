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
  before_action(:authenticate_user!, only: %i[
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
      is_BRI_book: is_BRI_book_adopter?,
      success: lambda {
        save_unverified_user(@handler_result.outputs.user.id)
        security_log(:educator_began_signup, { user: @handler_result.outputs.user })
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
        security_log(:educator_verify_email_failed, email: @email)
        render(:educator_email_verification_form)
      }
    )
  end

  def educator_sheerid_form
    @sheerid_url = generate_sheer_id_url(user: current_user)
    security_log(:user_viewed_sheerid_form, user: current_user)
  end

  # SheerID makes a POST request to this endpoint when it verifies an educator
  # http://developer.sheerid.com/program-settings#webhooks
  def sheerid_webhook
    handle_with(
      EducatorSignup::SheeridWebhook,
      verification_id: sheerid_provided_verification_id_param,
      success: lambda {
        security_log(:sheerid_webhook_received, { data: @handler_result })
        render(status: :ok, plain: 'Success')
      },
      failure: lambda {
        security_log(:sheerid_webhook_failed, { data: @handler_result })
        Sentry.capture_message(
          '[SheerID Webhook] Failed!',
          extra: {
            verification_id: sheerid_provided_verification_id_param,
            reason: @handler_result.errors.first.code
          }
        )
        render(status: :unprocessable_entity)
      }
    )
  end

  def educator_profile_form
    @book_titles = book_data.titles
    security_log(:user_viewed_profile_form, form_name: action_name, user: current_user)
  end

  def educator_complete_profile
    handle_with(
      EducatorSignup::CompleteProfile,
      user: current_user,
      success: lambda {
        user = @handler_result.outputs.user
        security_log(:user_profile_complete, { user: user })
        clear_incomplete_educator

        if user.is_educator_pending_cs_verification?
          redirect_to(educator_pending_cs_verification_path)
        else
          redirect_to(signup_done_path)
        end
      },
      failure: lambda {
        @book_titles = book_data.titles
        security_log(:educator_sign_up_failed, user: current_user, reason: @handler_result.errors)
        if @handler_result.outputs.is_on_cs_form
          redirect_to(educator_cs_verification_form_url, alert: "Please check your input and try again. Email address and School Name are required fields.")
        else
          render :educator_profile_form
        end
      }
    )
  end

  def educator_pending_cs_verification
    security_log(:user_sent_to_cs_for_review, user: current_user)
    @email_address = current_user.email_addresses.last&.value
  end

  private #################

  def store_if_sheerid_is_unviable_for_user
    if is_school_not_supported_by_sheerid? || is_country_not_supported_by_sheerid?
      current_user.update!(is_sheerid_unviable: true)
      security_log(:user_not_viable_for_sheerid, user: current_user)
    end
  end

  def exit_signup_if_steps_complete
    case true
    when current_user.is_educator_pending_cs_verification && current_user.pending_faculty?
      redirect_to(educator_pending_cs_verification_path)
    when current_user.is_educator_pending_cs_verification && !current_user.pending_faculty?
      redirect_back(fallback_location: profile_newflow_path)
    when action_name == 'educator_sheerid_form' && current_user.step_3_complete?
      redirect_to(educator_profile_form_path)
    when action_name == 'educator_profile_form' && current_user.is_profile_complete?
      redirect_to(profile_newflow_path)
    end
  end

  def book_data
    @book_data ||= FetchBookData.new
  end

  def store_sheerid_verification_for_user
    if sheerid_provided_verification_id_param.present? && current_user.sheerid_verification_id.blank?
      # create the verification object - this is verified later in SheeridWebhook
      SheeridVerification.find_or_initialize_by(verification_id: sheerid_provided_verification_id_param)

      # update the user
      current_user.update!(sheerid_verification_id: sheerid_provided_verification_id_param)

      # log it
      SecurityLog.create!(
        event_type: :sheerid_verification_id_added_to_user_during_signup,
        user: current_user,
        event_data: { verification_id: sheerid_provided_verification_id_param }
      )
    end
  end

end
