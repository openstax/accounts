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
  before_action(:exit_signup_if_steps_complete, only: %i[
      educator_sheerid_form
      educator_profile_form
      educator_cs_verification_form
    ]
  )

  def sheerid_form
    store_if_sheerid_is_unviable_for_user
    store_sheerid_verification_for_user
    @sheerid_url = generate_sheer_id_url(user: current_user)
    security_log(:user_viewed_sheerid_form, user: current_user)
  end

  # SheerID makes a POST request to this endpoint when it verifies an educator
  # http://developer.sheerid.com/program-settings#webhooks
  def sheerid_webhook
    handle_with(
      EducatorSignup::SheeridWebhook,
      verification_id: params[:verificationId],
      success: lambda {
        security_log(:sheerid_webhook_received, { data: @handler_result })
        render(status: :ok, plain: 'Success')
      },
      failure: lambda {
        security_log(:sheerid_webhook_failed, { data: @handler_result })
        if is_real_production?
          Sentry.capture_message(
            '[SheerID Webhook] Failed!',
            extra: {
              verification_id: params[:verificationid],
              reason: @handler_result.errors.first.code
            }
          )
        end
        render(status: :unprocessable_entity)
      }
    )
  end

  def profile_form
    @book_titles = book_data.titles
    security_log(:user_viewed_profile_form, form_name: action_name, user: current_user)
  end

  def profile_form_post
    handle_with(
      EducatorSignup::CompleteProfile,
      user: current_user,
      success: lambda {
        user = @handler_result.outputs.user
        security_log(:user_profile_complete, { user: user })
        clear_incomplete_educator

        if user.is_educator_pending_cs_verification?
          redirect_to(educator_pending_cs_verification_path) and return
        else
          redirect_to(signup_done_path) and return
        end
      },
      failure: lambda {
        @book_titles = book_data.titles
        security_log(:educator_sign_up_failed, user: current_user, reason: @handler_result.errors)
        render :profile_form
      }
    )
  end

  def pending_cs_verification_form
    security_log(:user_sent_to_cs_for_review, user: current_user)
    @email_address = current_user.email_addresses.last&.value
  end

  protected

  def generate_sheer_id_url(user)
    url = Addressable::URI.parse(Rails.application.secrets[:sheer_id_base_url])
    if url.present?
      url.query_values = url.query_values.merge(
        first_name: user.first_name,
        last_name:  user.last_name,
        email:      user.email_addresses.first&.value
      )
      url.to_s
    else
      Sentry.capture_message('Unable to generate SheerID URL for user.')
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

  def store_if_sheerid_is_unviable_for_user
    if params[:school].present? || params[:country].present?
      current_user.update!(is_sheerid_unviable: true)
      security_log(:user_not_viable_for_sheerid, user: current_user)
    end
  end

  def store_sheerid_verification_for_user
    if params[:verificationId].present? && current_user.sheerid_verification_id.blank?
      # create the verification object - this is verified later in SheeridWebhook
      SheeridVerification.find_or_initialize_by(
        verification_id: params[:verificationId])

      # update the user
      current_user.update!(sheerid_verification_id: params[:verificationId])

      # log it
      SecurityLog.create!(
        event_type: :sheerid_verification_id_added_to_user_during_signup,
        user: current_user,
        event_data: { verification_id: params[:verificationId] }
      )
    end
  end

end
