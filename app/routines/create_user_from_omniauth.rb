

class CreateUserFromOmniauth

  include Lev::Routine

  uses_routine CreateUser,
               translations: { outputs: {type: :verbatim} }

protected

  def exec(auth)
    case auth[:provider]
    when "facebook"
      create_from_facebook_auth(auth)
    when "identity"
      # All new "identity" users will already have their user by now.
      raise Unexpected
    when "twitter"
      create_from_twitter_auth(auth)
    else
      raise IllegalArgument, "unknown auth provider: #{auth[:provider]}"
    end
  end

  def create_from_facebook_auth(auth)
    run(CreateUser, username: normalize_username(auth[:info][:nickname]), 
                    ensure_no_errors: true)
  end

  def create_from_twitter_auth(auth)
    run(CreateUser, username: normalize_username(auth[:info][:nickname]), 
                    ensure_no_errors: true)
  end

  def normalize_username(username)
    username.gsub(DISCARDED_USERNAME_CHAR_REGEX,'').downcase.slice(0..49)
  end

end