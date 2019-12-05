require 'rails_helper'

RSpec.describe SsoCookieJar, type: :lib do
  let(:secrets)                { Rails.application.secrets.sso }

  let(:signature_public_key)   { OpenSSL::PKey::RSA.new secrets[:signature_public_key] }
  let(:signature_algorithm)    { secrets[:signature_algorithm].to_sym }

  let(:encryption_private_key) { secrets[:encryption_private_key] }
  let(:encryption_algorithm)   { secrets[:encryption_algorithm].to_s }
  let(:encryption_method)      { secrets[:encryption_method].to_s }

  let(:request)                { ActionController::TestRequest.create(:test) }
  let(:cookies)                { request.cookie_jar }

  it 'can write a cookie and read it back' do
    cookies.sso.subject = { foo: :bar }

    expect(cookies['oxa']).not_to be_blank # it's encrypted, so it's hard to predict its value
    expect(cookies.sso.subject).to eq('foo' => 'bar') # json means string keys
  end

  it 'sso cookies can be decoded using the sso secrets' do
    value = { 'test-answer': 42 }
    cookies.sso.subject = value

    expect(
      JSON::JWT.decode(
        JSON::JWT.decode(
          cookies['oxa'], encryption_private_key, encryption_algorithm, encryption_method
        ).plain_text, signature_public_key, signature_algorithm
      )['sub'].deep_symbolize_keys
    ).to eq value
  end
end
