# recaptcha_tags, recaptcha_v3, and verify_recaptcha come from the recaptcha gem
# Our own helpers are named slightly differently to avoid conflicts
module Recaptcha
  module View
    def recaptcha_with_disclaimer_and_fallback(action:, **options)
      disclaimer = <<~HTML.squish.html_safe
        <div class="content recaptcha-disclaimer">
          This site is protected by reCAPTCHA and the Google
          <a href="https://policies.google.com/privacy">Privacy Policy</a> and
          <a href="https://policies.google.com/terms">Terms of Service</a> apply.
        </div>
      HTML

      return disclaimer if Recaptcha.configuration.site_key.blank? && Rails.env.development?

      (@recaptcha_failed ? recaptcha_tags(**options) : recaptcha_v3(action: action, **options)) + disclaimer
    end
  end

  module Controller
    MINIMUM_SCORE = 0.2

    def self.included(base)
      base.helper View
    end

    def verify_recaptcha_with_fallback(**options)
      force_recaptcha_failure = params[:force_recaptcha_failure] == 'true'

      return !force_recaptcha_failure if Recaptcha.configuration.site_key.blank? && Rails.env.development?

      options = {
        action: action_name,
        minimum_score: MINIMUM_SCORE,
        **options
      }

      options[:response] = 'bogus' if force_recaptcha_failure

      verify_recaptcha(**options).tap { |result| @recaptcha_failed = !result }
    end
  end
end
