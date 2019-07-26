require 'rails_helper'

RSpec.describe SsoCookieJar do

  let(:sso_secret) {
    Rails.application.secrets.sso[:shared_secret]
  }

  let(:sso_salt) {
    Rails.application.secrets.sso[:shared_secret_salt]
  }

  let(:sso_signed_salt) {
    "signed encrypted #{sso_salt}"
  }

  let(:key_generator) {
    # ActiveSupport::CachingKeyGenerator.new(
      ActiveSupport::KeyGenerator.new(sso_secret, iterations: 1000)
    # )
  }

  let(:request) {
    OpenStruct.new(
      key_generator: key_generator,
      encrypted_cookie_salt: sso_salt,
      encrypted_signed_cookie_salt: sso_signed_salt,
      cookies_rotations: Rails.application.config.action_dispatch.cookies_rotations,
      cookies_serializer: Rails.application.config.action_dispatch.cookies_serializer,
    )
  }

  let(:cookies) { {} }

  it "can write a cookie and read it back" do
    sso_cookie_jar = SsoCookieJar.build(request, cookies)
    sso_cookie_jar.encrypted['some_name'] = {
      value: { foo: :bar }
    }

    expect(sso_cookie_jar['some_name']).not_to be_blank # it's encrypted, so it's hard to predict its value
    expect(sso_cookie_jar.encrypted['some_name']).to eq ({ 'foo' => 'bar' }) # json means string keys
  end

  it 'cookie jar can be decoded using key' do
    sso_cookie_jar = SsoCookieJar.build(request, cookies)
    sso_cookie_jar.encrypted['ox'] = {
      value: { 'test-answer' => 4242 }
    }

    salt = request.encrypted_cookie_salt
    secret = request.key_generator.generate_key(salt)[0,
      OpenSSL::Cipher.new('aes-256-cbc').key_len]

    sign_secret = request.key_generator.generate_key(request.encrypted_signed_cookie_salt)

    # encryptor = ActiveSupport::MessageEncryptor.new(secret, sign_secret, serializer: ActiveSupport::MessageEncryptor::NullSerializer)
    # encryptor = ActiveSupport::MessageEncryptor.new(secret, sign_secret, serializer: request.cookies_serializer)
    encryptor = ActiveSupport::MessageEncryptor.new(
      secret,
      sign_secret,
      serializer: request.cookies_serializer,
      cipher: 'aes-256-cbc',
    )

    cookie = sso_cookie_jar['ox']

    expect(
      encryptor.decrypt_and_verify(cookie)
    ).to eq({ 'test-answer' => 4242 })
  end
end
