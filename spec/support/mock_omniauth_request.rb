
class MockOmniauthRequest

  def initialize(provider, uid, info, params = {})
    @provider = provider
    @uid = uid
    @info = info
    @params = params
  end

  def env
    {
      'omniauth.auth' => { provider: @provider, uid: @uid, info: @info },
      'omniauth.params' => @params
    }
  end

end
