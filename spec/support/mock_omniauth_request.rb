class MockOmniauthRequest
  def initialize(provider, uid, info, params = {})
    @provider = provider
    @uid = uid
    @info = info
    @params = params
  end

  def env
    @env ||= {
      'omniauth.auth' => { provider: @provider, uid: @uid, info: @info },
      'omniauth.params' => @params,
      ActionDispatch::Cookies::GENERATOR_KEY => Rails.application.key_generator
    }
  end

  def host
    'localhost'
  end

  def ssl?
    true
  end

  def remote_ip
    Faker::Internet.ip_v4_address
  end

  def cookies
    ActionController::TestRequest.create(:test).cookie_jar
  end
end
