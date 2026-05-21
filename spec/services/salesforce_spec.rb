require 'rails_helper'

RSpec.describe Salesforce do
  describe '.configure' do
    it 'yields the configuration object' do
      Salesforce.configure do |config|
        config.username = 'u'
        config.password = 'p'
        config.security_token = 't'
        config.consumer_key = 'ck'
        config.consumer_secret = 'cs'
      end
      expect(Salesforce.configuration.username).to eq('u')
    end
  end

  describe Salesforce::Configuration do
    it 'defaults api_version' do
      expect(described_class.new.api_version).to eq('61.0')
    end

    it 'defaults login_domain' do
      expect(described_class.new.login_domain).to eq('test.salesforce.com')
    end

    it 'raises if required fields missing on validate!' do
      expect { described_class.new.validate! }.to raise_error(Salesforce::IllegalState)
    end
  end
end
