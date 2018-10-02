require 'rails_helper'

RSpec.describe SsoCookieJar do

  let(:mock_request) {
    OpenStruct.new(
      env: {
        ActionDispatch::Cookies::GENERATOR_KEY => Rails.application.key_generator
      },
      cookies: {}
    )
  }

  it "can write a cookie and read it back" do
    sso_cookie_jar = SsoCookieJar.build(mock_request)

    sso_cookie_jar.encrypted['some_name'] = {
      value: { foo: :bar }
    }

    # works
    expect(sso_cookie_jar['some_name']).not_to be_blank

    # fails - down in activesupport-4.2.7.1/lib/active_support/message_encryptor.rb:92,
    # `cipher.final` raises a `OpenSSL::Cipher::CipherError`
    expect(sso_cookie_jar.encrypted['some_name']).not_to be_blank
  end

end
