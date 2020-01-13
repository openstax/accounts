module Newflow
  # Handles the OAuth callback for social providers like facebook and google.
  #
  # We don't need to act on users' behalf on social media,
  # we just need to identify users by their `uid`.
  class OauthCallback
    lev_handler
    uses_routine(
      TransferAuthentications,
      translations: {
        inputs: {
          map: { authentication: :email_address }
        }
      },
      raise_fatal_errors: true
    )

    include Rails.application.routes.url_helpers

    protected #########################

    def authorized?
      true
    end

    def setup
      @oauth_provider = oauth_data.provider
      outputs.email = oauth_data.email
    end

    # rubocop:disable Metrics/AbcSize
    def handle
      authentication = Authentication.find_by(provider: @oauth_provider, uid: oauth_data.uid.to_s)
      if authentication
        # User found with the given authentication.
        # We will log them in.
      elsif (existing_user = LookupUsers.by_verified_email(oauth_data.email).first)
        # No user found with the given authentication, but a user *was* found with the given email address.
        # We will add the authentication to their existing account and then log them in.
        authentication = Authentication.new(provider: @oauth_provider, uid: oauth_data.uid.to_s)
        run(TransferAuthentications, authentication, existing_user) # TODO: does this raise fatally?
      else # sign up new user, then log them in.
        user = create_user_instance
        create_email_address(user)
        authentication = create_authentication(user, @oauth_provider)
      end

      outputs.authentication = authentication
      outputs.user = authentication.user
    end
    # rubocop:enable Metrics/AbcSize

    private ###########################

    def oauth_response
      request.env['omniauth.auth']
    end

    def oauth_data
      @oauth_data ||= parse_oauth_data(oauth_response)
    end

    def create_user_instance
      user = User.new(state: 'unverified')
      user.full_name = oauth_data.name
      transfer_errors_from(user, { type: :verbatim }, :fail_if_errors)
      user
    end

    def create_authentication(user, oauth_provider)
      auth = Authentication.new(provider: oauth_provider, uid: oauth_data.uid.to_s)
      run(TransferAuthentications, auth, user) # This persists the user and the authentication
      auth
    end

    def create_email_address(user)
      if EmailAddress.verified.where(value: oauth_data.email).exists?
        fatal_error(code: :email_already_in_use)
      end
      # Note: omniauth checks that Google emails are verified
      # while the facebook API only returns verified emails
      email = EmailAddress.create(value: oauth_data.email, user: user, verified: true)
      transfer_errors_from(email, { scope: :email_address }, :fail_if_errors)
      email
    end

    def parse_oauth_data(oauth_response)
      OmniauthData.new(oauth_response)
    rescue StandardError
      fatal_error(code: :invalid_omniauth_data)
    end
  end
end
