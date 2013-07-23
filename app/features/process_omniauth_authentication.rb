
# Takes omniauth authentication data and the current user, connects
# the auth data with the appropriate user, and returns the user that
# should be logged in (may or may not be the user that is already 
# logged in)
class ProcessOmniauthAuthentication

  def self.exec(auth_data, current_user)

    # Find a matching Authentication or create one if none exists
    authentication = Authentication.find_with_omniauth(auth_data) ||
                     Authentication.create_with_omniauth(auth_data)
 
    if current_user.present?

      if authentication.user == current_user
        # The current user is already associated with the incoming auth info --> no op.
      elsif authentication.user.nil?
        # The authentication is new (no user yet), so attach it to current_user
        authentication.user = current_user
        authentication.save
      else 
        # The authentication is associated to a user other than current_user; we have
        # two users belonging to the same person, so they should be merged.
        raise NotYetImplemented
      end

    else # no user is signed_in

      if authentication.user.present?
        # The authentication has an associated user so let's say the he/she should be logged in
        new_current_user = authentication.user
      else
        # The authentication has no attached user and there is no user signed in,
        # so let's make a new user and attach the authentication.  If it turns out
        # later that the underlying person has a different user account with a 
        # different authentication, when they authenticate this new user with that
        # other authentication provider, the user merging case above will be triggered.
        new_current_user = CreateUserFromOmniauth.new.exec(auth_data)
        new_current_user.authentications << authentication
      end

    end

    # Return the user who should be logged in
    new_current_user || current_user
  end

end