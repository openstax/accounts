# Handles the OAuth callback for social providers like facebook and google.
#
# We don't need to act on users' behalf on social media,
# we just need to identify users by their `uid`.
class OauthCallback

  include LoginSignupHelper

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
    @logged_in_user = options[:logged_in_user]

    @oauth_provider = oauth_data.provider
    @oauth_uid = oauth_data.uid.to_s
    outputs.email = oauth_data.email
  end

  def handle # rubocop:disable Metrics/AbcSize
    if @logged_in_user
      handle_while_logged_in(@logged_in_user.id)
    elsif (outputs.authentication = Authentication.find_by(provider: @oauth_provider, uid: @oauth_uid))
      # User found with the given authentication. We will log them in.
      outputs.authentication.user
    elsif (existing_user = user_most_recently_used(users_matching_oauth_data))
      # No user found with the given authentication, but a user *was* found with the given email address.
      # We will add the authentication to their existing account and then log them in.
      outputs.authentication = Authentication.find_or_initialize_by(provider: @oauth_provider, uid: @oauth_uid)
      run(TransferAuthentications, outputs.authentication, existing_user)
    # TODO: what is this?
    elsif user_came_from&.to_sym == :login_form
      # The user is trying to sign up but they came from the login form, so redirect them to the sign up form
      fatal_error(code: :should_redirect_to_signup)
    else # sign up new student, then we will log them in.
      user = create_student_user_instance
      run(TransferOmniauthData, oauth_data, user)
      outputs.authentication = create_authentication(user, @oauth_provider)
    end

    outputs.user = outputs.authentication.user
  end

  private

  # users can only have one login per social provider, so if user is trying to log in with
  # the same provider but it has a different uid, then they might've gotten the social account hacked,
  # so we want to prevent the hacker from logging in with the stolen social provider auth.
  def mismatched_authentication?
    return false if oauth_data.email.blank?

    existing_email_owner_id = LookupUsers.by_verified_email_or_username(oauth_data.email).last&.id
    existing_auth_uid       = Authentication.where(user_id: existing_email_owner_id, provider: @oauth_provider).pluck(:uid).first
    incoming_auth_uid       = Authentication.where(provider: @oauth_provider, uid: @oauth_uid).last&.uid

    if existing_auth_uid != incoming_auth_uid
      Sentry.capture_message('mismatched authentication', extra: { oauth_response: oauth_response })
      return true
    else
      return false
    end
  end

  def handle_while_logged_in(logged_in_user_id)
    outputs.authentication = authentication = Authentication.find_or_initialize_by(provider: @oauth_provider, uid: @oauth_uid)

    if authentication.user&.activated?
      fatal_error(
        code: :authentication_taken,
        message: I18n.t(:"controllers.sessions.sign_in_option_already_used")
      )
    end

    if is_email_taken?(oauth_data.email, logged_in_user_id)
      fatal_error(
        code: :email_already_in_use,
        offending_inputs: :email,
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

    these_user_ids = SecurityLog.arel_table[:user_id].in(users.map(&:id))
    user_id_by_sign_in = SecurityLog.sign_in_successful.where(these_user_ids).first&.user_id

    if user_id_by_sign_in.present?
      return users.select{|uu| uu.id == user_id_by_sign_in}.first
    end

    return users.sort_by{ |uu| [uu.updated_at, uu.created_at] }.last
  end

  def oauth_data
    @oauth_data ||= parse_oauth_data(oauth_response)
  end

  def create_student_user_instance
    user = User.new(state: 'unverified', role: :student)
    user.full_name = oauth_data.name

    transfer_errors_from(user, { type: :verbatim }, :fail_if_errors)
    user
  end

  def create_authentication(user, oauth_provider)
    auth = Authentication.new(provider: oauth_provider, uid: @oauth_uid)
    run(TransferAuthentications, auth, user)
    auth
  end

  def parse_oauth_data(oauth_response)
    OmniauthData.new(oauth_response)
  rescue StandardError
    fatal_error(code: :invalid_omniauth_data)
  end

  def is_email_taken?(email, logged_in_user_id)
    ContactInfo.verified.where(value: email).where.not(user_id: logged_in_user_id).exists?
  end

  def oauth_response
    request.env['omniauth.auth']
  end

  def user_came_from
    request.env['omniauth.origin']
  end

end
