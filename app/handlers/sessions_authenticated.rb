
# Handles omniauth authentication data.
#
# Callers must supply:
#   1) a request with an 'omniauth.auth' env that contains values for these keys:
#        :provider --> the Oauth provider
#        :uid --> the ID of the user from the Oauth provider
#   2) a 'user_state' object which has the following methods:
#        sign_in(user)
#        sign_out!
#        signed_in?
#        current_user
#
# In the result object, this handler will return a :next_action, which will
# be one of: :return_to_app, :ask_which_account, :ask_new_or_returning
#
#
class SessionsAuthenticated 

  include Lev::Handler

  uses_routine TransferAuthentications
  uses_routine CreateUserFromOmniauth
  uses_routine DestroyUser
  uses_routine TransferOmniauthInformation

protected

  def setup
    @auth_data = request.env['omniauth.auth']
    @user_state = options[:user_state]
  end

  def authorized?
    true
  end

  def handle
    # Get an authentication object for the incoming data, tracking if we have
    # the object didn't yet exist and we had to create it.

    authentication_data = { provider: @auth_data[:provider], uid: @auth_data[:uid]}
    authentication = Authentication.where(authentication_data).first
    
    this_authentication_is_new = authentication.nil?
    authentication = Authentication.create(authentication_data) if this_authentication_is_new

    authentication_user = authentication.user

    if authentication_user.nil?
      # check for existing users matching auth_data emails
      matching_users = UsersWithEmails.all(@auth_data[:emails])

      case matching_users.size
      when 0
      when 1
        authentication_user = matching_users.first
        run(TransferAuthentications, authentication, authentication_user)  
      else
        # For the moment don't do anything.  Could try to let the user choose
        # one of these other users to attach to, but that's 
      end
    end

    if authentication_user.present?

      if signed_in?
        if authentication_user.is_temp && current_user.is_temp
          first_user_lives_second_user_dies(current_user, authentication_user)
          outputs[:next_action] = :ask_new_or_returning
        elsif authentication_user.is_temp
          first_user_lives_second_user_dies(current_user, authentication_user)
          outputs[:next_action] = :return_to_app
        elsif current_user.is_temp
          first_user_lives_second_user_dies(authentication_user, current_user)
          outputs[:next_action] = :return_to_app
        else
          if current_user.id == authentication_user.id
            outputs[:next_action] = :return_to_app
          else
            outputs[:next_action] = :ask_which_account
          end 
        end
      else
        sign_in(authentication_user)
        outputs[:next_action] = (authentication_user.is_temp ? :ask_new_or_returning : :return_to_app)
      end
      
    else

      if signed_in?
        run(TransferAuthentications, authentication, current_user)
        outputs[:next_action] = (current_user.is_temp ? :ask_new_or_returning : :return_to_app)
      else
        outcome = run(CreateUserFromOmniauth, @auth_data)
        new_user = outcome.outputs[:user]
        run(TransferAuthentications, authentication, new_user)
        sign_in(new_user)
        outputs[:next_action] = :ask_new_or_returning
      end

    end 

    if this_authentication_is_new
      run(TransferOmniauthInformation, @auth_data, current_user)
    end

  end

protected

  def current_user
    @user_state.current_user
  end

  def signed_in?
    @user_state.signed_in?
  end

  def sign_in(user)
    @user_state.sign_in(user)
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
      sign_in(living_user)
    end
  end

end