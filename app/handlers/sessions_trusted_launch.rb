class SessionsTrustedLaunch

  attr_reader :signup_state

  lev_handler

  protected

  def authorized?
    true
  end

  def setup
    @signup_state = options[:signup_state]
  end

  def handle

    uuid_link = UserAlternativeUuid.find_by_uuid(signup_state.trusted_data['uuid'])
    if uuid_link.present?
      outputs[:user] = uuid_link.user
      signup_state.sign_in!(outputs[:user])
      return
    end

    if signup_state.trusted_data['email']
       user = LookupUsers.by_verified_email(signup_state.trusted_data['email']).first
       if user
         UserAlternativeUuid.create(user: user, uuid: trusted_state['uuid'])
         signup_state.sign_in!(user)
         outputs[:user] = user
         return
       end
    end

  end

end
