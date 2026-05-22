# Wrap in to_prepare so Zeitwerk doesn't unload Salesforce (and our config
# with it) after initialization. Without this we hit the Rails autoload-
# during-init deprecation warning and the configured api_version etc. are
# lost on first reload, falling back to the Configuration class defaults.
Rails.application.reloader.to_prepare do
  Salesforce.configure do |config|
    secrets = Rails.application.secrets.salesforce
    config.username        = secrets[:username]
    config.password        = secrets[:password]
    config.security_token  = secrets[:security_token]
    config.consumer_key    = secrets[:consumer_key]
    config.consumer_secret = secrets[:consumer_secret]
    # Matches the version VCR cassettes were recorded against. Bumping requires
    # re-recording cassettes under spec/cassettes/.
    config.api_version     = secrets.fetch(:api_version, '51.0')
    config.login_domain    = secrets.fetch(:login_domain, 'test.salesforce.com')
  end
end
