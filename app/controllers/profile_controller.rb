class ProfileController < ApplicationController

  skip_before_action :authenticate_user!, only: :exit_accounts

  def profile
    prevent_caching
    redirect_instructors_needing_to_complete_signup
    redirect_back_if_allowed
  end

  def exit_accounts
    if (redirect_param = extract_params(request.referer)[:r])
      if Host.trusted?(redirect_param)
        redirect_to(redirect_param)
      else
        raise Lev::SecurityTransgression
      end
    elsif !signed_in? && (redirect_uri = extract_params(stored_url)[:redirect_uri])
      redirect_to(redirect_uri)
    else
      redirect_back(fallback_location: :login_path)
    end
  end
end
