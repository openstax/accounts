# recaptcha_tags, recaptcha_v3, and verify_recaptcha come from the recaptcha gem
# Our own helpers are named slightly differently to avoid conflicts
module Recaptcha
  def self.secrets
    Rails.application.secrets.recaptcha || {}
  end

  module View
    def recaptcha_with_fallback(action:, **options)
      if @recaptcha_failed
        recaptcha_tags
      else
        recaptcha_v3 action: action, site_key: Recaptcha.secrets[:site_key], **options
      end
    end
  end

  module Controller
    MINIMUM_SCORE = 0.2

    def self.included(base)
      base.helper View
    end

    def verify_recaptcha_with_fallback(**options)
      params = {
        action: action_name,
        minimum_score: MINIMUM_SCORE,
        secret_key: Recaptcha.secrets[:secret_key],
        **options
      }

      params[:response] = 'bogus' if params[:secret_key].blank? && Rails.env.development?

      verify_recaptcha(**params).tap { |result| @recaptcha_failed = !result }
    end
  end
end
