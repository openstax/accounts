module Newflow
  class BaseController < ApplicationController
    include ApplicationHelper

    skip_before_action :authenticate_user!, :check_if_password_expired

    before_action :newflow_authenticate_user!, only: :profile_newflow
    before_action :set_active_banners

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

    private #################

    def set_active_banners
      return unless request.get?

      @banners ||= Banner.active
    end
  end
end
