# Parses and then represents the response from authenticating with a social provider.
class OmniauthData

  VALID_PROVIDERS = %w[identity facebook google]

  def initialize(auth_data)
    @auth_data = auth_data
    @info = @auth_data[:info] || {}
    raise IllegalArgument unless VALID_PROVIDERS.include?(provider)
  end

  def provider
    @auth_data[:provider]
  end

  def uid
    @auth_data[:uid]
  end

  def name
    @info[:name]
  end

  def nickname
    # The User model will sanitize this
    @info[:nickname] || name
  end

  def first_name
    @info[:first_name]
  end

  def last_name
    @info[:last_name]
  end

  def email
    # Facebook only returns verified emails
    # Twitter returns no emails
    # Google can return unverified emails
    # However, the omniauth-google-oauth2 gem filters those out
    @info[:email]
  end

  def image
    @info[:image]
  end

end
