# This initializer always runs before the engine is loaded, but it can
# also be copied to the application's initializers by running the install
# task. Because this code can get run multiple times, make sure to only put
# code here that is amenable to that.

OpenStax::Salesforce.configure do |config|
  salesforce_secrets = Rails.application.secrets.salesforce

  # Connected App credentials for the OAuth client credentials flow. The login domain
  # must be the org's My Domain: Salesforce rejects this flow at login/test.salesforce.com.
  config.consumer_key    = salesforce_secrets[:consumer_key]
  config.consumer_secret = salesforce_secrets[:consumer_secret]

  config.api_version  = salesforce_secrets.fetch :api_version, '51.0'
  config.login_domain = salesforce_secrets.fetch :login_domain, 'test.salesforce.com'
end
