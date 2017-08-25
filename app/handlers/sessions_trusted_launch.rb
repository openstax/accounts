class SessionsTrustedLaunch

  attr_reader :user_state, :trusted_state

  lev_handler

  protected

  def authorized?
    true
  end

  def setup
    @trusted_state = options[:trusted_state]
    @user_state = options[:user_state]
  end

  def handle

    uuid_link = UserAlternativeUuid.find_by_uuid(trusted_state['uuid'])
    if uuid_link.present?
      outputs[:user] = uuid_link.user
      user_state.sign_in!(outputs[:user])
      return
    end

    if trusted_state['email']
       user = LookupUsers.by_verified_email(trusted_state['email']).first
       if user
         UserAlternativeUuid.create(user: user, uuid: trusted_state['uuid'])
         user_state.sign_in!(user)
         outputs[:user] = user
         return
       end
    end

    signup_state = SignupState.email_address.create(contact_info_value: trusted_state['email'],
                                                    role: trusted_state['role'],
                                                    verified: true)

    user_state.save_signup_state(signup_state)
  end

end
