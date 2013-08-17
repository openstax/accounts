

class HandleOmniauthAuthentication 

  include Feature

  # user_state has methods 
  #   sign_in(user)
  #   sign_out!
  #   signed_in?
  #   current_user
  #
  def initialize(auth_data, user_state)
    @auth_data = auth_data
    @user_state = user_state
  end

protected

  def exec

    # Find a matching Authentication or create one if none exists
    authentication = Authentication.find!(@auth_data['provider'], 
                                          @auth_data['provider_uid'])
    authentication_user = authentication.user

    if authentication_user.nil?
      # check for existing users matching auth_data emails
      matching_users = UsersWithEmails.all(auth_data.emails)

      case matching_users.size
      when 0
      when 1
        authentication_user = matching_users.first
        run(TransferAuthentications, authentication, authentication_user)  
      else
        raise NotYetImplemented
      end
    end

    if authentication_user.present?

      if signed_in?
        if current_user_is_temp?
          # move temp user auths to authentication user, destroy and
          # sign out the temp user, then sign in the authentication user        
          run(TransferAuthentications, current_user.authentications, authentication_user)  
          run(DestroyUser, current_user)
          sign_out!
          sign_in(authentication_user)
        else
          if current_user.id == authentication_user.id
            # return to app
          else
            # choose which to login as
          end 
        end
      else
        sign_in(authentication_user)
        # return to app
      end
      
    else

      if signed_in?
        run(TransferAuthentications, authentication, current_user)

        if current_user_is_temp?
          # ask if new or returning
        else
          # return to app
        end
      else
        new_user = run(CreateUser)
        run(TransferAuthentications, authentication, new_user)
        sign_in(new_user)
        # ask if new or returning
      end

    end 


  end

protected

  def current_user
    @user_state.current_user
  end

  def current_person
    current_user.present? ? current_user.person : nil
  end

  def signed_in?
    @user_state.signed_in?
  end

  def sign_in?(user)
    @user_state.sign_in(user)
  end

  def sign_out!
    @user_state.sign_out!
  end

  def current_user_is_temp?
    current_person.nil?
  end

end