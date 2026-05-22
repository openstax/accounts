require 'rails_helper'

RSpec.describe Salesforce::Client do
  before do
    Salesforce.configure do |c|
      c.username = 'u'
      c.password = 'p'
      c.security_token = 't'
      c.consumer_key = 'ck'
      c.consumer_secret = 'cs'
      c.api_version = '61.0'
      c.login_domain = 'test.salesforce.com'
    end
  end

  after { Salesforce.reset_configuration! }

  it 'is a Restforce client' do
    expect(described_class.new).to be_a(Restforce::Data::Client)
  end

  it 'passes configured credentials through to Restforce::Data::Client#initialize' do
    expect_any_instance_of(Restforce::Data::Client).to receive(:initialize).with(
      hash_including(
        username: 'u',
        password: 'p',
        security_token: 't',
        client_id: 'ck',
        client_secret: 'cs',
        api_version: '61.0',
        host: 'test.salesforce.com'
      )
    ).and_call_original
    described_class.new
  end
end
