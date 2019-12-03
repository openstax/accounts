module Newflow
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
      # TODO: remove the case switch when we deploy to production
      @oauth_provider = case @data.provider
                        when 'facebooknewflow'
                          'facebook'
                        when 'googlenewflow'
                          'google_oauth2'
                        else
                          @data.provider
                        end

      outputs.email = @data.email
    end

    # rubocop:disable Metrics/AbcSize
    def handle
      authentication = Authentication.find_by(provider: @oauth_provider, uid: @data.uid.to_s)
      if authentication
        security_log(:sign_in_successful, authentication.user, authentication_id: authentication.id)
      elsif (existing_user = LookupUsers.by_verified_email(@data.email).first)
        authentication = Authentication.new(provider: @oauth_provider, uid: @data.uid.to_s)
        run(TransferAuthentications, authentication, existing_user) # TODO: does this raise fatally?
        security_log(:sign_in_successful, authentication.user, authentication_id: authentication.id)
      else # sign up new user
        user = create_user_instance
        create_email_address(user)
        authentication = create_authentication(user, @oauth_provider)
        security_log(:sign_up_successful, user, authentication_id: authentication.id)
      end

      outputs.user = authentication.user
      outputs.pre_auth_state = outputs.user.pre_auth_state
    end
    # rubocop:enable Metrics/AbcSize

    private ###########################

    def create_user_instance
      user = User.new(state: 'unverified')
      user.full_name = @data.name
      transfer_errors_from(user, { type: :verbatim }, :fail_if_errors)
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
end
