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
    @came_from = parse_oauth_origin(request.env['omniauth.origin'])
    @data = parse_oauth_response(request.env['omniauth.auth'])
    # TODO: undo the following line when we deploy to production
    @oauth_provider = @data.provider == 'facebooknewflow' ? 'facebook' : @data.provider
  end

  # rubocop:disable Metrics/AbcSize
  def handle
    authentication = Authentication.find_by(provider: @oauth_provider, uid: @data.uid.to_s)

    if logging_in?
      unless authentication
        # user has not signed up or added facebook as authentication
        security_log(:sign_in_failed, nil, reason: 'mismatched authentication')
        fatal_error(code: :TODO)
      end

      security_log(:sign_in_successful, authentication.user, authentication_id: authentication.id)
      outputs.user = authentication.user
    elsif signing_up? && authentication # trying to sign up but already did so before
      # just log them in
      security_log(:sign_in_successful, authentication.user, authentication_id: authentication.id)
      outputs.user = authentication.user
    elsif signing_up?
      user = create_user_instance
      create_email_address(user)
      authentication = create_authentication(user, @oauth_provider)
      security_log(:sign_up_successful, user, authentication_id: authentication.id)
      outputs.user = user
      # TODO: redirect to page where users can confirm their info we got from social provider
      # outputs.destination_path = confirm_social_info_path or something like that
    else
      # perhaps create a sec log entry
      fatal_error(code: :unknown_callback_state)
    end
  end
  # rubocop:enable Metrics/AbcSize

  private ###########################

  def create_user_instance
    state = 'activated' # b/c emails from oauth providers are already verified
    user = User.new(state: state)
    user.full_name = @data.name
    user
  end

  def create_authentication(user, oauth_provider)
    auth = Authentication.new(provider: oauth_provider, uid: @data.uid.to_s)
    # Note that this persists the user and the authentication
    run(TransferAuthentications, auth, user)
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

  def parse_oauth_origin(oauth_origin)
    URI.parse(oauth_origin).path
  end

  def parse_oauth_response(oauth_response)
    OmniauthData.new(oauth_response)
  rescue StandardError
    fatal_error(code: :invalid_omniauth_data)
  end

  def logging_in?
    @came_from == newflow_login_path
  end

  def signing_up?
    @came_from == newflow_signup_path
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
