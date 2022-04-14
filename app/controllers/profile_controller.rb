class ProfileController < ApplicationController

  before_action :authenticate_user!, only: :profile
  before_action :prevent_caching, only: :profile

  def profile
    return if current_user.student?

    if current_user.sheerid_verification_id.present? || current_user.is_sheerid_unviable? || current_user.is_profile_complete?
      security_log(:educator_resumed_signup_flow, message: 'User needs to complete SheerID verification. Redirecting.')
      redirect_to sheerid_form_path
    elsif current_user.sheerid_verification_id.blank? && current_user.pending_faculty? && !current_user.is_educator_pending_cs_verification
      security_log(:educator_resumed_signup_flow, message: 'User needs to complete instructor profile. Redirecting.')
      render :profile
    end
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

end
