
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
      'omniauth.params' => @params
    }
  end

  def host
    'localhost'
  end

  def ssl?
    false
  end

  def cookies
    {}
  end

  def sso_cookie_jar
    env["action_dispatch.sso_cookies".freeze] ||= SsoCookieJar.build(self)
  end

end
