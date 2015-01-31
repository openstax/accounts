
class MockOmniauthRequest

  def initialize(provider, uid, info)
    @provider = provider
    @uid = uid
    @info = info
  end

  def env
    { 'omniauth.auth' => { provider: @provider, uid: @uid, info: @info } }
  end

end