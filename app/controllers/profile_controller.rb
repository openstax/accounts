class ProfileController < ApplicationController

  before_action :authenticate_user!, only: :profile
  before_action :ensure_complete_educator_signup, only: :profile
  before_action :prevent_caching, only: :profile

  def profile
    render layout: 'application'
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
