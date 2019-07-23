require 'rails_helper'

RSpec.describe SsoCookieJar do

  let(:mock_request) {
    OpenStruct.new(
      env: {},
      cookies: {}
    )
  }

  it "can write a cookie and read it back" do
    sso_cookie_jar = SsoCookieJar.build(mock_request, {})

    sso_cookie_jar.encrypted['some_name'] = {
      value: { foo: :bar }
    }

    expect(sso_cookie_jar['some_name']).not_to be_blank # encrypted so hard to predict real value
    expect(sso_cookie_jar.encrypted['some_name']).to eq ({ 'foo' => 'bar' }) # json means string keys
  end

  it 'cookie jar can be decoded using key' do
    sso_cookie_jar = SsoCookieJar.build(mock_request, {})

    sso_cookie_jar.encrypted['ox'] = {
      value: { 'test-answer' => 4242 }
    }

    secret_key_base = Rails.application.secrets.sso[:shared_secret]
    cookie          = sso_cookie_jar['ox']
    salt            = Rails.application.secrets.sso[:shared_secret_salt]
    signed_salt     = "signed encrypted #{salt}"
    key_generator   = ActiveSupport::KeyGenerator.new(secret_key_base, iterations: 1000)
    secret          = key_generator.generate_key(salt)[0, OpenSSL::Cipher.new('aes-256-cbc').key_len]
    sign_secret     = key_generator.generate_key(signed_salt)
    encryptor       = ActiveSupport::MessageEncryptor.new(secret, sign_secret, serializer: JSON)

    expect(
      encryptor.decrypt_and_verify(cookie)
    ).to eq({ 'test-answer' => 4242 })
  end
end
