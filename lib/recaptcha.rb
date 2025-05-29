# recaptcha_tags, recaptcha_v3, and verify_recaptcha come from the recaptcha gem
# Our own helpers are named slightly differently to avoid conflicts
module Recaptcha
  module View
    DEFAULT_BADGE_POSITION = 'bottomleft'

    def recaptcha_with_fallback(action:, **options)
      if @recaptcha_failed
        recaptcha_tags badge: DEFAULT_BADGE_POSITION, **options
      else
        recaptcha_v3 action: action, badge: DEFAULT_BADGE_POSITION, **options
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
        **options
      }

      params[:response] = 'bogus' if Recaptcha.configuration.site_key.blank? && Rails.env.development?

      verify_recaptcha(**params).tap { |result| @recaptcha_failed = !result }
    end
  end
end
