class EducatorSignupController < SignupController
  include EducatorSignupHelper

  skip_forgery_protection(only: :sheerid_webhook)

  before_action :prevent_caching, only: :sheerid_webhook

  before_action(:check_if_signup_complete, only: %i[
      sheerid_form
      profile_form
      pending_cs_verification_form
    ]
  )

  def sheerid_form
    @sheerid_url = generate_sheer_id_url(user: current_user)
    security_log(:user_viewed_sheerid_form, user: current_user)
  end

  # SheerID makes a POST request to this endpoint when it verifies an educator
  # http://developer.sheerid.com/program-settings#webhooks
  def sheerid_webhook
    handle_with(
      SheeridWebhook,
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

  def profile_form
    store_if_sheerid_is_unviable_for_user
    store_sheerid_verification_for_user
    security_log(:user_viewed_profile_form, form_name: action_name, user: current_user)
  end

  def profile_post
    handle_with(
      CompleteEducatorProfile,
      user: current_user,
      success: lambda {
        user = @handler_result.outputs.user
        security_log(:user_profile_complete, { user: user })
        clear_incomplete_educator

        if user.is_educator_pending_cs_verification?
          redirect_to(cs_verification_path)
        else
          redirect_to(signup_done_path)
        end
      },
      failure: lambda {
        security_log(:educator_sign_up_failed, user: current_user, reason: @handler_result.errors)
        if @handler_result.outputs.is_on_cs_form
          redirect_to(cs_verification_form_url, alert: "Please check your input and try again. Email address and School Name are required fields.")
        else
          render :profile_form
        end
      }
    )
  end

  def pending_cs_verification; end

  def pending_cs_verification_form
    render :profile_form
  end

  def pending_cs_verification_post
    security_log(:user_sent_to_cs_for_review, user: current_user)
    @email_address = current_user.email_addresses.last&.value
  end

  private

  def store_if_sheerid_is_unviable_for_user
    if is_school_not_supported_by_sheerid? || is_country_not_supported_by_sheerid?
      current_user.update!(is_sheerid_unviable: true)
      security_log(:user_not_viable_for_sheerid, user: current_user)
    end
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

  def generate_sheer_id_url(user:)
    url = Addressable::URI.parse(Rails.application.secrets.sheerid_base_url)
    url.query_values = url.query_values.merge(
      first_name: user.first_name,
      last_name:  user.last_name,
      email:      user.email_addresses.first&.value
    )
    url.to_s
  end
end
