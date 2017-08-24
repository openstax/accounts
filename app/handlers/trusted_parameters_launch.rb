class TrustedParametersLaunch

  attr_reader :user_state, :attrs

  lev_handler

  protected

  def authorized?
    true
  end

  def setup
    @attrs = request.session['trusted']
    @user_state = options[:user_state]
  end

  def handle

    uuid_link = UserAlternativeUuid.find_by_uuid(attrs[:uuid])
    if uuid_link.present?
      outputs[:user] = uuid_link.user
      user_state.sign_in!(outputs[:user])
      return
    end

    if attrs['email']
       user = LookupUsers.by_verified_email(attrs['email']).first
       if user
         UserAlternativeUuid.create(user: user, uuid: attrs['uuid'])
         user_state.sign_in!(user)
         outputs[:user] = user
         return
       end
    end

    signup_state = SignupState.email_address.create(contact_info_value: attrs['email'],
                                                    role: attrs['role'],
                                                    verified: true,
                                                    return_to: options[:return_to])

    user_state.save_signup_state(signup_state)
  end

end
