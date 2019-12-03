require 'rails_helper'

RSpec.describe OldSsoCookieJar, type: :lib do
  let(:secrets)       { Rails.application.secrets.sso }
  let(:key_generator) do
    ActiveSupport::CachingKeyGenerator.new(
      ActiveSupport::KeyGenerator.new(
        secrets[:shared_secret], iterations: secrets.fetch(:iterations, 1000)
      )
    )
  end
  let(:salt)          { secrets[:shared_secret_salt] }
  let(:cipher)        { secrets.fetch(:cipher, 'aes-256-cbc') }
  let(:encryptor)     do
    ActiveSupport::MessageEncryptor.new(
      key_generator.generate_key(salt, OpenSSL::Cipher.new(cipher).key_len),
      key_generator.generate_key("signed encrypted #{salt}"),
      cipher: cipher, serializer: ActiveSupport::MessageEncryptor::NullSerializer
    )
  end

  let(:request)       { ActionController::TestRequest.create(:test) }
  let(:cookies)       { request.cookie_jar }

  it 'can write a cookie and read it back' do
    cookies.old_sso[:some_name] = { value: { foo: :bar } }

    expect(cookies[:some_name]).not_to be_blank # it's encrypted, so it's hard to predict its value
    expect(cookies.old_sso[:some_name]).to eq('foo' => 'bar') # json means string keys
  end

  it 'sso cookies can be decoded using the sso secrets' do
    value = { 'test-answer': 42 }
    cookies.old_sso['ox'] = { value: value }

    expect(encryptor.decrypt_and_verify(cookies['ox'])).to eq value.to_json
  end
end
