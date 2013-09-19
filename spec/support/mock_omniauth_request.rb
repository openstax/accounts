
class MockOmniauthRequest

  def initialize(provider, uid, emails)
    @provider = provider
    @uid = uid
    @emails = emails
  end

  def env
    {'omniauth.auth' => {provider: @provider, uid: @uid, emails: @emails}}
  end

end