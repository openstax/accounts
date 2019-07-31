require 'rails_helper'

RSpec.describe SsoCookieJar do

  let(:json_serializer) {
    ActionDispatch::Cookies::JsonSerializer
  }

  let(:sso_shared_secret) {
    Rails.application.secrets.sso[:shared_secret]
  }

  let(:sso_shared_salt) {
    Rails.application.secrets.sso[:shared_secret_salt] # || 'cookie'
  }

  let(:key_generator) {
    ActiveSupport::CachingKeyGenerator.new(
      ActiveSupport::KeyGenerator.new(sso_shared_secret, iterations: 1000)
    )
  }

  let(:request) {
    OpenStruct.new(
      key_generator: key_generator,
      encrypted_cookie_salt: sso_shared_salt,
      encrypted_signed_cookie_salt: "signed encrypted #{sso_shared_salt}",
      cookies_rotations: Rails.application.config.action_dispatch.cookies_rotations,
      cookies_serializer: json_serializer,
      # use_authenticated_cookie_encryption: Rails.application.config.action_dispatch.use_authenticated_cookie_encryption,
      use_authenticated_cookie_encryption: false,
      secret_key_base: sso_shared_secret,
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
    # request['cookie_jar'] = sso_cookie_jar
    sso_cookie_jar = SsoCookieJar.build(request, cookies)

    sso_cookie_jar.encrypted['ox'] = {
      value: { 'test-answer' => 4242 }
    }

    # salt = request.encrypted_cookie_salt
    # secret = request.key_generator.generate_key(salt)[0, OpenSSL::Cipher.new('aes-256-cbc').key_len]

    # signed_salt = request.encrypted_signed_cookie_salt
    # sign_secret = request.key_generator.generate_key(signed_salt)

    # encryptor = ActiveSupport::MessageEncryptor.new(
    #   secret,
    #   sign_secret,
    #   cipher: 'aes-256-cbc',
    #   serializer: ActiveSupport::MessageEncryptor::NullSerializer,
    #   )


    sso_shared_secret = Rails.application.secrets.sso[:shared_secret]
    sso_shared_salt = Rails.application.secrets.sso[:shared_secret_salt]
    sso_signed_salt = "signed encrypted #{sso_shared_salt}"

    key_length = OpenSSL::Cipher.new('aes-256-cbc').key_len

    sso_keygen = ActiveSupport::CachingKeyGenerator.new(
      ActiveSupport::KeyGenerator.new(sso_shared_secret, iterations: 1000)
    )
    secret = sso_keygen.generate_key(sso_shared_salt)[0, key_length]
    sign_secret = sso_keygen.generate_key(sso_signed_salt)

    json_serializer = ActionDispatch::Cookies::JsonSerializer
    sso_encryptor = ActiveSupport::MessageEncryptor.new(secret, sign_secret, serializer: json_serializer)

    cookie = sso_cookie_jar['ox']

    expect(
      sso_encryptor.decrypt_and_verify(cookie)
    ).to eq(
      { 'test-answer' => 4242 }.to_json
    )
  end
end
