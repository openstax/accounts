# Handles the OAuth callback for social providers like facebook and google.
#
# We don't need to act on users' behalf on social media,
# we just need to identify users by their `uid`.
class OauthCallback
  lev_handler
  uses_routine TransferAuthentications,
               translations: {
                 inputs: {
                   map: { authentication: :email_address }
                 }
               },
               raise_fatal_errors: true

  include Rails.application.routes.url_helpers

  protected #########################

  def authorized?
    true
  end

  def setup
    @data = parse_oauth_data(request.env['omniauth.auth'])
    # TODO: undo the following line when we deploy to production
    @oauth_provider = @data.provider == 'facebooknewflow' ? 'facebook' : @data.provider
  end

  # rubocop:disable Metrics/AbcSize
  def handle
    authentication = Authentication.find_by(provider: @oauth_provider, uid: @data.uid.to_s)

    if logging_in?
      unless authentication # if no Authentication found
        existing_user = LookupUsers.by_verified_email(@data.email).first
        if existing_user
          # if user is trying to login with social, but they didn't signup with social, look them
          # up by email address and if found, add the social auth strategy to their account
          new_auth = Authentication.new(provider: @oauth_provider, uid: @data.uid.to_s)
          new_auth.user = existing_user
          new_auth.save! # TODO: `save` instead
          authentication = new_auth
        else
          # if user has not signed up or added facebook as authentication
          security_log(:sign_in_failed, nil, reason: 'mismatched authentication')
          fatal_error(code: :TODO)
        end
      end

      security_log(:sign_in_successful, authentication.user, authentication_id: authentication.id)
    elsif (existing_user = LookupUsers.by_verified_email(@data.email).first)
      authentication = Authentication.new(provider: @oauth_provider, uid: @data.uid.to_s)
      # TransferAuthentications.call(authentication, existing_user) # TODO: does this raise fatally?
      run(TransferAuthentications, authentication, existing_user) # TODO: does this raise fatally?
      security_log(:sign_in_successful, authentication.user, authentication_id: authentication.id)
    else # sign up new user
      user = create_user_instance
      create_email_address(user)
      authentication = create_authentication(user, @oauth_provider)
      security_log(:sign_up_successful, user, authentication_id: authentication.id)
      outputs.user = user
      # TODO: redirect to page where users can confirm their info we got from social provider
      # outputs.destination_path = confirm_social_info_path or something like that

      # elsif # adding an authentication (while logged in) to their account
    end

    outputs.user = authentication.user
  end
  # rubocop:enable Metrics/AbcSize

  private ###########################

  def create_user_instance
    state = 'activated' # b/c we trust emails from oauth providers to be already verified
    user = User.new(state: state)
    user.full_name = @data.name
    user
  end

  def create_authentication(user, oauth_provider)
    auth = Authentication.new(provider: oauth_provider, uid: @data.uid.to_s)
    run(TransferAuthentications, auth, user) # This persists the user and the authentication
    auth
  end

  def create_email_address(user)
    if EmailAddress.verified.where(value: @data.email).exists?
      fatal_error(code: :email_already_in_use)
    end
    # Note: omniauth checks that Google emails are verified
    # while the facebook API only returns verified emails
    email = EmailAddress.create(value: @data.email, user: user, verified: true)
    transfer_errors_from(email, { scope: :email_address }, :fail_if_errors)
    email
  end

  def parse_oauth_data(oauth_response)
    OmniauthData.new(oauth_response)
  rescue StandardError
    fatal_error(code: :invalid_omniauth_data)
  end

  def security_log(event, user, data = {})
    SecurityLog.create!(
      user: user,
      remote_ip: request.remote_ip,
      event_type: event,
      event_data: data
    )
  end
end
