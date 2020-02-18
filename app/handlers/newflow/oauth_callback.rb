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
    uses_routine(TransferOmniauthData)

    include Rails.application.routes.url_helpers

    protected #########################

    def authorized?
      true
    end

    def setup
      @oauth_provider = oauth_data.provider
      @oauth_uid = oauth_data.uid.to_s
      outputs.email = oauth_data.email
    end

    # rubocop:disable Metrics/AbcSize
    def handle
      if options[:logged_in_user]
        newflow_handle_while_logged_in
      elsif mismatched_authentication?
        fatal_error(code: :mismatched_authentication)
      elsif (outputs.authentication = Authentication.find_by(provider: @oauth_provider, uid: @oauth_uid))
        # User found with the given authentication.
        # We will log them in.
      elsif (existing_user = user_most_recently_used(users_matching_oauth_data))
        # No user found with the given authentication, but a user *was* found with the given email address.
        # We will add the authentication to their existing account and then log them in.
        outputs.authentication = Authentication.find_or_initialize_by(provider: @oauth_provider, uid: @oauth_uid)
        run(TransferAuthentications, outputs.authentication, existing_user)
      else # sign up new user, then we will log them in.
        user = create_user_instance
        run(TransferOmniauthData, oauth_data, user)
        outputs.authentication = create_authentication(user, @oauth_provider)
      end

      outputs.user = outputs.authentication.user
    end
    # rubocop:enable Metrics/AbcSize

    private ###########################

    # somebody already owns this oauth email adddress,
    # and it's not the same user that that own this Authentication (found by uid)
    def mismatched_authentication?
      incoming_auth = Authentication.find_by(provider: @oauth_provider, uid: @oauth_uid)
      existing_email_owner = LookupUsers.by_verified_email(oauth_data.email).first
      existing_auth = Authentication.where(user_id: existing_email_owner.id, provider: @oauth_provider).pluck(:uid).first
      existing_auth != incoming_auth.uid
    end

    def newflow_handle_while_logged_in
      outputs.authentication = authentication = Authentication.find_or_initialize_by(provider: @oauth_provider, uid: @oauth_uid)

      if authentication.user && authentication.user.is_activated?
        fatal_error(
          code: :authentication_taken,
          message: I18n.t(:"controllers.sessions.sign_in_option_already_used")
        )
      end

      if ContactInfo.verified.where(value: oauth_data.email).where.has { |t| t.user_id != options[:logged_in_user].id }.exists?
        fatal_error(
          code: :email_already_in_use,
          # offending_inputs: input_field,
          message: I18n.t(:"login_signup_form.sign_in_option_already_used")
        )
      end

      # add the authentication to their account
      run(TransferAuthentications, authentication, options[:logged_in_user])

      authentication
    end

    def users_matching_oauth_data
      # We find potential matching users by comparing their email addresses to
      # what comes back in the OAuth data.  We trust that Google/FB/ omniauth
      # strategies will only give us verified emails.
      #
      #   true for Google (omniauth strategy checks that the emails are verified)
      #   true for FB (their API only returns verified emails)

      @users_matching_oauth_data ||= EmailAddress.where(value: oauth_data.email)
                                                                    .verified
                                                                    .with_users
                                                                    .map(&:user)
    end

    def user_most_recently_used(users)
      return nil if users.empty?
      return users.first if users.one?

      user_id_by_sign_in = SecurityLog.sign_in_successful
                                      .where.has{ |t| t.user_id.in users.map(&:id)}
                                      .first
                                      .try(&:user_id)

      if user_id_by_sign_in.present?
        return users.select{|uu| uu.id == user_id_by_sign_in}.first
      end

      return users.sort_by{ |uu| [uu.updated_at, uu.created_at] }.last
    end

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
      auth = Authentication.new(provider: oauth_provider, uid: @oauth_uid)
      run(TransferAuthentications, auth, user) # This persists the user and the authentication
      auth
    end

    def parse_oauth_data(oauth_response)
      OmniauthData.new(oauth_response)
    rescue StandardError
      fatal_error(code: :invalid_omniauth_data)
    end
  end
end
