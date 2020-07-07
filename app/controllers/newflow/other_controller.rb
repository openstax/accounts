module Newflow
  class OtherController < BaseController
    before_action :newflow_authenticate_user!, only: :profile_newflow
    before_action :prevent_caching, only: :profile_newflow

    def profile_newflow
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
end
