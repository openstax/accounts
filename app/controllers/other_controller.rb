class OtherController < Newflow::BaseController

  before_action :newflow_authenticate_user!, only: [:profile_newflow, :dismiss_profile_nudge]
  before_action :ensure_complete_educator_signup, only: :profile_newflow
  before_action :prevent_caching, only: :profile_newflow

  def profile_newflow
    if current_user.needs_profile_nudge? && !session[:profile_nudge_dismissed]
      @show_profile_nudge_banner = true

      unless SecurityLog.exists?(user: current_user, event_type: :profile_nudge_banner_shown)
        security_log(:profile_nudge_banner_shown)
      end
    end

    render layout: 'application'
  end

  # A plain button_to (full-page POST), not an AJAX call -- consistent with
  # the rest of this page, which has no JS form-submission wiring. Redirects
  # back rather than a bare 204 so it works as an ordinary form submission.
  def dismiss_profile_nudge
    session[:profile_nudge_dismissed] = true
    redirect_to(profile_newflow_path)
  end

  def exit_accounts
    if (redirect_param = extract_params(request.referrer)[:r])
      if Host.trusted?(redirect_param)
        redirect_to(redirect_param)
      else
        raise Lev::SecurityTransgression
      end
    elsif !signed_in? && (redirect_uri = extract_params(stored_url)[:redirect_uri])
      redirect_to(redirect_uri)
    else
      redirect_back # defined in the `action_interceptor` gem
    end
  end

  private

  # The first time an educator with an incomplete profile reaches this page
  # they're bounced to finish step 4 -- but once that has already happened
  # once (`profile_nudge_redirected_at` set, either here or by the login
  # nudge redirect), bouncing them again on every visit would make the
  # profile-nudge banner below unreachable. From then on this page renders
  # normally and the banner does the reminding instead.
  def ensure_complete_educator_signup
    return if current_user.student?

    if decorated_user.incomplete_step_3?
      security_log(:educator_resumed_signup_flow, message: 'User needs to complete SheerID verification. Redirecting.')
      redirect_to(educator_sheerid_form_path)
    elsif decorated_user.incomplete_step_4? && current_user.profile_nudge_redirected_at.nil?
      stamp_profile_nudge_redirected_at
      security_log(:educator_resumed_signup_flow, message: 'User needs to complete instructor profile. Redirecting.')
      redirect_to(educator_profile_form_path)
    end
  end

  # Bookkeeping must never break this redirect, so a failed write is
  # swallowed the same way sign_in! swallows a failed last_signed_in_at write.
  def stamp_profile_nudge_redirected_at
    current_user.update_column(:profile_nudge_redirected_at, Time.current)
  rescue StandardError => e
    Rails.logger.error(
      "Failed to record profile_nudge_redirected_at for user #{current_user.id}: #{e.message}"
    )
  end

end
