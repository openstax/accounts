recaptcha_secrets = Rails.application.secrets.recaptcha || {}
Recaptcha.configure do |config|
  config.site_key = recaptcha_secrets[:site_key]
  config.secret_key = recaptcha_secrets[:secret_key]
end

# recaptcha_tags, recaptcha_v3, and verify_recaptcha come from the recaptcha gem
# Our own helpers are named slightly differently to avoid conflicts

module RecaptchaView
  DISCLAIMER = <<~HTML.squish.html_safe
    <div class="content recaptcha-disclaimer">
      This site is protected by reCAPTCHA and the Google
      <a href="https://policies.google.com/privacy">Privacy Policy</a> and
      <a href="https://policies.google.com/terms">Terms of Service</a> apply.
    </div>
  HTML

  FAILURE_MESSAGE = <<~HTML.squish.html_safe
    <div class="content recaptcha-failure">
      reCAPTCHA verification failed.
      Please try a different browser or contact support.
    </div>
  HTML

  def recaptcha_with_disclaimer_and_fallback(action:, **options)
    return DISCLAIMER if Recaptcha.configuration.site_key.blank? && Rails.env.development?

    recaptcha_or_message = @recaptcha_failed ? FAILURE_MESSAGE : recaptcha_v3(action: action, **options)

    recaptcha_or_message + DISCLAIMER + <<~HTML.squish.html_safe
      <input type="hidden" name="force_recaptcha_failure" value="#{params[:force_recaptcha_failure]}">
    HTML
  end
end

module RecaptchaController
  MINIMUM_SCORE = 0.2

  def self.included(base)
    base.helper RecaptchaView
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
