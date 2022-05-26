class ProfileController < ApplicationController

  before_action :authenticate_user!, only: :profile
  before_action :prevent_caching, only: :profile
  before_action :user_signup_complete_check, only: :profile

  def profile; end

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
