recaptcha_secrets = Rails.application.secrets.recaptcha || {}
Recaptcha.configure do |config|
  config.site_key = recaptcha_secrets[:site_key]
  config.secret_key = recaptcha_secrets[:secret_key]
end

STUB_RECAPTCHA = !Rails.env.production? && Recaptcha.configuration.site_key.blank?

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
      We couldn't automatically verify that submission. Go ahead and try
      again below -- nothing you entered was lost.
    </div>
  HTML

  # reCAPTCHA v3 is a risk signal, not a gate: the widget (and a working,
  # freshly-mintable token) must always be present, even on a re-rendered
  # form after a failed attempt. Showing FAILURE_MESSAGE *instead of* the
  # widget was the original incident -- the retry then carried no token and
  # failed forever.
  def recaptcha_with_disclaimer_and_fallback(action:, **options)
    return DISCLAIMER + force_recaptcha_failure_field if STUB_RECAPTCHA

    token_input_id = "recaptcha-token-#{action}"
    execute_fn = Recaptcha::Helpers.recaptcha_v3_async_execute_function_name(action)
    failure_notice = @recaptcha_failed ? FAILURE_MESSAGE : ''.html_safe

    widget_open = %(<div class="recaptcha-widget" data-recaptcha-action="#{action}" data-recaptcha-execute-fn="#{execute_fn}" data-recaptcha-input-id="#{token_input_id}">).html_safe

    widget_open +
      recaptcha_v3(action: action, **options, id: token_input_id) +
      failure_notice +
      '</div>'.html_safe +
      DISCLAIMER +
      force_recaptcha_failure_field
  end

  private

  # A manual QA affordance for exercising the failure path in a non-production
  # environment that has a real reCAPTCHA key configured (STUB_RECAPTCHA only
  # covers environments with *no* key). It must never reach production output
  # -- it was previously interpolated unescaped into an HTML attribute here,
  # a reflected-XSS hole reachable via the query string on every signup page.
  def force_recaptcha_failure_field
    return ''.html_safe if Rails.env.production?

    %(<input type="hidden" name="force_recaptcha_failure" value="#{ERB::Util.html_escape(params[:force_recaptcha_failure])}">).html_safe
  end
end

module RecaptchaController
  def self.included(base)
    base.helper RecaptchaView
  end

  # reCAPTCHA is a risk signal, not a gate: the only outcome that blocks a
  # submission is Google completing the call and returning a score below the
  # configured minimum. Anything else -- no token, a timeout, a network
  # error, an unreachable API -- allows the request through and logs why, so
  # a Google outage or an adblocked script can never lock a real user out.
  def verify_recaptcha_with_fallback(**options)
    force_recaptcha_failure = params[:force_recaptcha_failure] == 'true'

    # Return true if recaptcha is disabled via admin setting
    return true if Settings::Recaptcha.disabled?

    return !force_recaptcha_failure if STUB_RECAPTCHA

    minimum_score = Settings::Db.store.minimum_recaptcha_score
    options = { action: action_name, minimum_score: minimum_score, **options }
    options[:response] = 'bogus' if force_recaptcha_failure

    error_message = nil
    begin
      verify_recaptcha(**options)
    rescue Recaptcha::RecaptchaError, Timeout::Error => e
      error_message = "Recaptcha error: #{e.message}"
    end

    reply = recaptcha_reply || {}
    score = reply['score']

    # The gem's own score_above_threshold? treats a real 0.0 score like any
    # other number (0.0 is truthy in Ruby) -- but a *missing* score (nil,
    # from a timeout, network error, or missing token) must never read as
    # "below threshold". Only a genuine, present score under the minimum
    # blocks.
    blocked = !score.nil? && score.to_f < minimum_score.to_f

    security_log(
      blocked ? :recaptcha_blocked : :recaptcha_verified,
      recaptcha_action: options[:action],
      score: score,
      minimum_score: minimum_score,
      error_codes: reply['error-codes'],
      reason: error_message || recaptcha_failure_reason
    )
    log_posthog(current_user, 'recaptcha_verified', {
      recaptcha_action: options[:action],
      score: score,
      blocked: blocked
    })

    @recaptcha_failed = blocked
    !blocked
  end
end
