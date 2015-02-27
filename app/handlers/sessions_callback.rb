# Handles the omniauth callback.
#
# Callers must supply:
#   1) a request with an 'omniauth.auth' env that contains values for these keys:
#        :provider --> the Oauth provider
#        :uid --> the ID of the user from the Oauth provider
#
#   2) a 'user_state' object which has the following methods:
#        sign_in!(user)
#        sign_out!
#        signed_in?
#        current_user
#
# In the result object, this handler will return a :status, which will be:
#
# :returning_user, if the user is a returning user
# :new_user if the user has not registered yet
# :multiple_accounts if the user has 2+ accounts with the same email address
#
class SessionsCallback

  lev_handler

  uses_routine TransferAuthentications
  uses_routine CreateUserFromOmniauthData
  uses_routine TransferOmniauthData
  uses_routine DestroyUser

  protected

  def setup
    @data = OmniauthData.new(request.env['omniauth.auth'])
    @user_state = options[:user_state]
  end

  def authorized?
    true
  end

  def handle
    # Get an authentication object for the incoming data, tracking if
    # the object didn't yet exist and we had to create it.

    authentication_data = { provider: @data.provider,
                            uid: @data.uid.to_s }
    authentication = Authentication.where(authentication_data).first

    this_authentication_is_new = authentication.nil?
    authentication = Authentication.create(authentication_data) if this_authentication_is_new

    authentication_user = authentication.user

    if authentication_user.nil?
      # Check for existing users matching auth_data emails
      # Note: we trust that Google/FB/Twitter omniauth strategies
      #       will only give us verified emails.
      #   true for Google (omniauth strategy checks that the emails are verified)
      #   true for FB (their API only returns verified emails)
      #   true for Twitter (they don't return any emails)
      matching_users = EmailAddress.where(:value => @data.email)
                                   .verified.with_users.collect{|e| e.user}

      case matching_users.size
      when 0
      when 1
        authentication_user = matching_users.first
        run(TransferAuthentications, authentication, authentication_user)
      else
        # For the moment don't do anything.  Could try to let the user choose
        # one of these other users to attach to.
      end
    end

    if authentication_user.present?

      if signed_in?
        if authentication_user.is_temp? && current_user.is_temp?
          first_user_lives_second_user_dies(current_user, authentication_user)
          status = :new_user
        elsif authentication_user.is_temp?
          first_user_lives_second_user_dies(current_user, authentication_user)
          status = :returning_user
        elsif current_user.is_temp?
          first_user_lives_second_user_dies(authentication_user, current_user)
          status = :returning_user
        else
          if current_user.id == authentication_user.id
            status = :returning_user
          else
          status = :multiple_accounts
          end
        end
      else
        sign_in!(authentication_user)
        status = (authentication_user.is_temp? ? :new_user : :returning_user)
      end

    else

      if signed_in?
        run(TransferAuthentications, authentication, current_user)
        status = (current_user.is_temp? ? :new_user : :returning_user)
      else
        outcome = run(CreateUserFromOmniauthData, @data)
        new_user = outcome.outputs[:user]
        run(TransferAuthentications, authentication, new_user)
        sign_in!(new_user)
        status = :new_user
      end

    end

    if this_authentication_is_new
      run(TransferOmniauthData, @data, current_user)
    end

    outputs[:status] = status

  end

  protected

  def current_user
    @user_state.current_user
  end

  def signed_in?
    @user_state.signed_in?
  end

  def sign_in!(user)
    @user_state.sign_in!(user)
  end

  def sign_out!
    @user_state.sign_out!
  end

  # Moves authentications from dying to living user & destroys dying user
  # if those users are different.  If the living user isn't signed in, sign
  # it in
  def first_user_lives_second_user_dies(living_user, dying_user)
    if living_user != dying_user
      run(TransferAuthentications, dying_user.authentications, living_user)
      run(DestroyUser, dying_user)
    end
    if current_user != living_user
      sign_out!
      sign_in!(living_user)
    end
  end

end
