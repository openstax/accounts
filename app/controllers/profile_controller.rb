class ProfileController < ApplicationController

  skip_before_action :authenticate_user!, only: :exit_accounts
  before_action :prevent_caching, only: :profile

  layout 'application'

  def profile
    check_if_signup_complete
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
