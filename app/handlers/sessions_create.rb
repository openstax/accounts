# Handles the omniauth callback.
#
# Callers must supply:
#   1) a request with an 'omniauth.auth' env that contains values for these keys:
#        :provider --> the Oauth provider
#        :uid --> the ID of the user from the Oauth provider
#
#   2) a 'user_state' object which has the following methods:
#        sign_in!(user)
#        signed_in?
#        current_user
#
# In the result object, this handler will return a :status, which will be:
#
# :returning_user               if the user is a returning user
# :new_password_user            if the user just signed up as a password user
# :new_social_user              if the user is signing up and just authenticated socially
# :transferred_authentication   if the user signed up and we can find an existing
#                               user to add the auth to
# :authentication_added         if the user is adding an authentication from the profile page
# :no_action                    if the user is adding an authentication from the
#                               profile page that is already linked to them
#
# TODO clean up this comment
#
class SessionsCreate

  include RequireRecentSignin

  lev_handler

  uses_routine TransferAuthentications
  uses_routine TransferOmniauthData

  protected

  def setup
    @data = OmniauthData.new(request.env['omniauth.auth']) \
      rescue fatal_error(code: :invalid_omniauth_data)
    @user_state = options[:user_state]
  end

  def handle
    outputs[:status] = get_status
  end

  def get_status
    if signed_in?
      status = handle_while_logged_in

      # Return status if present or fallback to one of the other flows if status is nil
      return status unless status.nil?
    end

    if options[:login_providers].present?
      handle_during_login
    elsif signing_up?
      handle_during_signup
    else
      fatal_error(code: :unknown_callback_state)
    end
  end

  def handle_during_login
    # The incoming authentication must match an existing user and match the
    # authentications corresponding to the username/email provided during login.
    options[:login_providers].deep_stringify_keys!
    if authentication_user.nil? ||
      options[:login_providers][authentication.provider].nil? ||
      options[:login_providers][authentication.provider]['uid'] != authentication.uid
      return :mismatched_authentication
    end

    sign_in!(authentication_user)
    return :returning_user
  end

  def handle_during_signup
    # Before we proceed with the normal sign up flow, we need to check if the
    # incoming authentication is connected to an existing user (to prevent creating
    # a duplicate account).  We can detect this in two ways: if the authentication
    # is already in use by an existing user OR if the authentication's email is
    # in use by an existing user or users.  If there are multiple potential existing
    # users, choose the most recently used (anything to avoid making yet another
    # duplicate).

    existing_user = authentication_user || user_most_recently_used(users_matching_oauth_data)

    if existing_user.present?
      # Want to transfer the SCI and authentication to this existing user and sign that user in
      receiving_user = existing_user
      status         = :existing_user_signed_up_again
    else
      # This is the normal signup flow.  For password signups, we need to find
      # the existing user; for social, we need to make a new one.  Then we attach
      # the authentication.

      if authentication.provider == 'identity'
        identity       = Identity.find(authentication.uid)
        receiving_user = identity.user
        status         = :new_password_user # TODO can this merge with new_social_user?
      else
        receiving_user = User.new
        run(TransferOmniauthData, @data, receiving_user)
        status = :new_social_user
      end
    end

    run(TransferAuthentications, authentication, receiving_user)
    sign_in!(receiving_user)
    status
  end

  def handle_while_logged_in
    # Attempt to login when already logged in

    # Same user: don't do anything
    return :no_action if authentication_user == current_user

    # Check if they are trying to add a new authentication to their account
    if request.env['omniauth.params'].try!(:[], 'add') == 'true'
      # Add the new authentication
      return :authentication_taken if authentication_user && authentication_user.activated?

      return :same_provider \
        if current_user.authentications.map(&:provider).include?(authentication.provider)

      return :new_signin_required if user_signin_is_too_old?

      if ContactInfo.verified.where(value: @data.email).where.not(user_id: current_user.id).exists?
        return :email_already_in_use
      end

      run(TransferAuthentications, authentication, current_user)
      run(TransferOmniauthData, @data, current_user) if authentication.provider != 'identity'

      :authentication_added
    else
      # If no resolution, fallback to one of the other flows
      nil
    end
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
      user.state = 'activated'
      user.save
    end

    @user_state.sign_in!(user)
  end

  def users_matching_oauth_data
    # We find potential matching users by comparing their email addresses to
    # what comes back in the OAuth data.  We trust that Google/FB/ omniauth
    # strategies will only give us verified emails.
    #
    #   true for Google (omniauth strategy checks that the emails are verified)
    #   true for FB (their API only returns verified emails)

    @users_matching_oauth_data ||= EmailAddress.where(value: @data.email)
                                               .verified
                                               .with_users
                                               .map(&:user)
  end

  def user_most_recently_used(users)
    return nil if users.empty?
    return users.first if users.one?

    user_id_by_sign_in = SecurityLog.sign_in_successful
                                    .where(user_id: users.map(&:id))
                                    .first
                                    .try(&:user_id)

    if user_id_by_sign_in.present?
      return users.select { |uu| uu.id == user_id_by_sign_in }.first
    end

    return users.sort_by { |uu| [uu.updated_at, uu.created_at] }.last
  end

  def authentication
    # We don't use fatal_errors in this handler (we could, but we don't), so just build
    # don't create an authentication here because we don't want to leave orphaned
    # records lying around if we return a error-ish status

    outputs[:authentication] ||=
      Authentication.find_or_initialize_by(provider: @data.provider, uid: @data.uid.to_s)
                    .tap do |authentication|

        # Refresh google login hints if needed
        if @data.provider == 'google_oauth2'
          authentication.login_hint = @data.email
        end

      end
  end

  def authentication_user
    @authentication_user ||= authentication.user
  end

  def signing_up?
    Sentry.capture_message("User caught in session_create signup flow #{current_user.id}")
    return
  end

  def logging_in?
    options[:login_providers].present?
  end

end
