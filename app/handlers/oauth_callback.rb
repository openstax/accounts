# Handles the OAuth callback for social providers like facebook and google.
#
# We don't need to act on users' behalf on social media,
# we just need to identify users by their `uid`.
class OauthCallback

  include LoginSignupHelper

  lev_handler

  uses_routine(TransferOmniauthData)

  include Rails.application.routes.url_helpers

  protected

  def authorized?
    true
  end

  def handle
    # Possible errors that can occur - so we'll check those first
    if mismatched_authentication?
      fatal_error(code: :mismatched_authentication)
    # The user is trying to sign up but they came from the login form, so redirect them to the sign up form
    elsif request.env['omniauth.origin']&.to_sym == :login_form
      fatal_error(code: :should_redirect_to_signup)
    end

    @authentication = Authentication.find_or_initialize_by(provider: @oauth_data.provider, uid: @oauth_data.uid)
    user = User.find_by(id: @authentication.user_id)
    # User found with the given authentication. We will log them in.
    if user.present?
      outputs.user = user
      outputs.authentication = @authentication
    # No user found with the given authentication, but a user *was* found with the given email address.
    # We will add the authentication to their existing account and then log them in.
    elsif(existing_user = user_most_recently_used(users_matching_oauth_data))
      outputs.user = existing_user
      run(TransferOmniauthData, @oauth_data, existing_user)
      outputs.authentication = existing_user.authentications.last
    # This defaults to only allowing a student to signup with social - instructors can only add it on their profile
    # So we'll make sure this isn't an existing instructor user - then proceed to sign them up
    # (social signup is hidden on instructor signup)
    else
      user = User.create(role: 'student', faculty_status: 'no_faculty_info', state: 'unverified')
      outputs.user = user
      run(TransferOmniauthData, @oauth_data, user)
      outputs.authentication = user.authentications.last
    end
  end

  private

  # users can only have one login per social provider, so if user is trying to log in with
  # the same provider but it has a different uid, then they might've gotten the social account hacked,
  # so we want to prevent the hacker from logging in with the stolen social provider auth.
  def mismatched_authentication?
    return false if oauth_data.email.blank?

    existing_email_owner_id = LookupUsers.by_email_or_username(oauth_data.email).last&.id
    existing_auth_uid = Authentication.where(user_id: existing_email_owner_id, provider: oauth_data.provider).last&.uid
    incoming_auth_uid = Authentication.where(provider: oauth_data.provider, uid: oauth_data.uid).last&.uid

    return false unless existing_auth_uid != incoming_auth_uid

    Sentry.capture_message('mismatched authentication', extra: { oauth_response: oauth_response })
  end

  def users_matching_oauth_data
    # We find potential matching users by comparing their email addresses to what comes back in the OAuth data.
    # We trust that Google/FB/omniauth strategies will only give us verified emails.
    #
    # true for Google (omniauth strategy checks that the emails are verified)
    # true for FB (their API only returns verified emails)

    @users_matching_oauth_data ||= EmailAddress.where(value: oauth_data.email).verified.with_users.map(&:user)
  end

  def user_most_recently_used(users)
    return nil if users.empty?
    return users.first if users.one?

    these_user_ids = SecurityLog.arel_table[:user_id].in(users.map(&:id))
    user_id_by_sign_in = SecurityLog.sign_in_successful.where(these_user_ids).first&.user_id

    if user_id_by_sign_in.present?
      return users.select{|uu| uu.id == user_id_by_sign_in}.first
    end

    users.sort_by{ |uu| [uu.updated_at, uu.created_at] }.last
  end

  def oauth_data
    @oauth_data ||= OmniauthData.new(oauth_response)
  rescue StandardError
    fatal_error(code: :invalid_omniauth_data)
  end

  # TODO: is this is still needed?
  def handle_while_logged_in(user)
    if user&.activated?
      fatal_error(code: :authentication_taken,
                  message: I18n.t(:"controllers.sessions.sign_in_option_already_used"))
    end

    if ContactInfo.verified.where(value: user.email_addresses.any?).where.not(user_id: user).exists?
      fatal_error(code: :email_already_in_use, offending_inputs: :email,
                  message: I18n.t(:"login_signup_form.sign_in_option_already_used"))
    end
    # add the authentication to their account
    run(TransferAuthentications, @authentication, user)
  end

  def oauth_response
    request.env['omniauth.auth']
  end
end
