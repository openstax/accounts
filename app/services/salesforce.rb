module Salesforce
  class IllegalState < StandardError; end

  def self.configure
    yield configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset_configuration!
    @configuration = nil
  end

  class Configuration
    attr_writer :api_version, :login_domain
    attr_accessor :username, :password, :security_token, :consumer_key, :consumer_secret

    def api_version
      @api_version ||= '66.0'
    end

    def login_domain
      @login_domain ||= 'test.salesforce.com'
    end

    def validate!
      raise IllegalState, 'The Salesforce username is missing'        if username.nil?
      raise IllegalState, 'The Salesforce password is missing'        if password.nil?
      raise IllegalState, 'The Salesforce security token is missing'  if security_token.nil?
      raise IllegalState, 'The Salesforce consumer key is missing'    if consumer_key.nil?
      raise IllegalState, 'The Salesforce consumer secret is missing' if consumer_secret.nil?
    end
  end
end
