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
# :returning_user               if the user is a returning user
# :new_password_user            if the user just signed up as a password user
# :new_social_user              if the user is signing up and just authenticated socially
# :transferred_authentication   if the user signed up and we can find an existing user to add the auth to
# :authentication_added         if the user is adding an authentication from the profile page
# :no_action                    if the user is adding an authentication from the profile page that is already linked to them
#
class SessionsCreate

  include RequireRecentSignin

  lev_handler

  uses_routine TransferAuthentications
  uses_routine CreateUserFromOmniauthData
  uses_routine TransferOmniauthData
  uses_routine ActivateUnclaimedUser

  protected

  def setup
    @data = OmniauthData.new(request.env['omniauth.auth'])
    @user_state = options[:user_state]
  end

  def authorized?
    true
  end

  # TODO compare incoming social authentication with login_info in cookies to make
  # sure that the authentication matches the username or email that the user started
  # with

  def handle
    authentication =
      Authentication.find_or_create_by(provider: @data.provider, uid: @data.uid.to_s)
    authentication_user = authentication.user
    outputs[:authentication] = authentication

    if signed_in? && authentication_user == current_user
      status = :no_action

    elsif signed_in?
      # This is from adding authentications on the profile screen

      if authentication_user && authentication_user.is_activated?
        status = :authentication_taken
      else
        return outputs[:status] = :new_signin_required if user_signin_is_too_old?
        return outputs[:status] = :same_provider \
                                  if current_user.authentications.any?{|user_auth| user_auth.provider == authentication.provider}
        run(TransferAuthentications, authentication, current_user)
        run(TransferOmniauthData, @data, current_user) if authentication.provider != 'identity'
        status = :authentication_added
      end

    elsif authentication_user.present?
      sign_in!(authentication_user)
      status = :returning_user

    else
      # No authentication user, so we need to find or create a user to attach to

      if authentication.provider == 'identity'
        identity = Identity.find(authentication.uid)
        authentication_user = identity.user
        status = :new_password_user
      elsif users_matching_oauth_data.size == 1
        authentication_user = users_matching_oauth_data.first
        status = :transferred_authentication
      else
        outcome = run(CreateUserFromOmniauthData, @data)
        authentication_user = outcome.outputs[:user]
        run(TransferOmniauthData, @data, authentication_user)
        status = :new_social_user
      end

      run(TransferAuthentications, authentication, authentication_user)
      sign_in!(authentication_user)
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
    if user.is_unclaimed?
      run(ActivateUnclaimedUser, user)
    end
    @user_state.sign_in!(user)
  end

  def sign_out!
    @user_state.sign_out!
  end

  def users_matching_oauth_data
    # We find potential matching users by comparing their email addresses to
    # what comes back in the OAuth data.
    #
    # Note: we trust that Google/FB/Twitter omniauth strategies
    #       will only give us verified emails.
    #
    #   true for Google (omniauth strategy checks that the emails are verified)
    #   true for FB (their API only returns verified emails)
    #   true for Twitter (they don't return any emails)

    @users_matching_oauth_data ||= EmailAddress.where(value: @data.email)
                                               .verified
                                               .with_users
                                               .map(&:user)
  end

end
