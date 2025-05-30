recaptcha_secrets = Rails.application.secrets.recaptcha || {}
Recaptcha.configure do |config|
  config.site_key = recaptcha_secrets[:site_key]
  config.secret_key = recaptcha_secrets[:secret_key]
end
