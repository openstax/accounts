Salesforce.configure do |config|
  secrets = Rails.application.secrets.salesforce
  config.username        = secrets[:username]
  config.password        = secrets[:password]
  config.security_token  = secrets[:security_token]
  config.consumer_key    = secrets[:consumer_key]
  config.consumer_secret = secrets[:consumer_secret]
  config.api_version     = secrets.fetch(:api_version, '61.0')
  config.login_domain    = secrets.fetch(:login_domain, 'test.salesforce.com')
end
