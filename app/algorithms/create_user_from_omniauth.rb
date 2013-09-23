

class CreateUserFromOmniauth

  include Lev::Algorithm

protected

  def exec(auth)
    case auth[:provider]
    when "facebook"
      create_from_facebook_auth(auth)
    when "identity"
      create_from_identity_auth(auth)
    when "twitter"
      create_from_twitter_auth(auth)
    else
      raise IllegalArgument, "unknown auth provider: #{auth[:provider]}"
    end
  end

  def create_from_identity_auth(auth)
    run(CreateUser, username: SecureRandom.hex(10), ensure_no_errors: true)
  end

  def create_from_facebook_auth(auth)
    run(CreateUser, username: auth[:info][:nickname], ensure_no_errors: true)
  end

  def create_from_twitter_auth(auth)
    run(CreateUser, username: auth[:info][:nickname], ensure_no_errors: true)
  end

end