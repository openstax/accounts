module Salesforce
  class Client < Restforce::Data::Client

    def initialize
      user = SalesforceUser.first
      if user.nil?
        Rails.logger.error { "The Salesforce client was requested but no user is available." }
        raise Salesforce::UserMissing
      end
      secrets = SECRET_SETTINGS[:salesforce]
      super(oauth_token: user.oauth_token,
            refresh_token: user.refresh_token,
            instance_url: user.instance_url,
            client_id: secrets['consumer_key'],
            client_secret: secrets['consumer_secret'],
            api_version: '37.0')
    end

  end
end
