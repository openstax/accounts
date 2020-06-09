module Newflow
  class OtherController < BaseController
    skip_forgery_protection(only: :sheerid_webhook)

    before_action :newflow_authenticate_user!, only: :profile_newflow

    def profile_newflow
      render layout: 'application'
    end

    # SheerID makes a POST request to this endpoint when it verifies an educator
    # http://developer.sheerid.com/program-settings#webhooks
    def sheerid_webhook
      handle_with(
        SheeridWebhook,
        success: lambda {
          render(status: :ok)
        },
        failure: lambda {
          render(status: :unprocessable_entity)
        }
      )
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
