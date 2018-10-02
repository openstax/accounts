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

    expect(sso_cookie_jar['some_name']).not_to be_blank # encrypted so hard to predict real value
    expect(sso_cookie_jar.encrypted['some_name']).to eq ({ foo: :bar })
  end

end
