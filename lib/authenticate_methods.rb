require 'addressable/uri'

module AuthenticateMethods

  def authenticate_user!
    use_signed_params if signed_params.present?

    return if signed_in?

    # Drop signed params from where we will go back after log in so we don't
    # try to use them again.
    store_url(url: request_url_without_signed_params)

    if signup_state && signup_state.trusted_student?
      redirect_to main_app.signup_path
    else
      redirect_to(
        main_app.login_path(
          params.slice(:client_id, :signup_at, :go, :no_signup)
        )
      )
    end
  end

  def authenticate_admin!
    return if current_user.is_administrator?

    store_url
    redirect_to main_app.login_path(params.slice(:client_id))
  end

  # Doorkeeper controllers define authenticate_admin!, so we need another name
  alias_method :admin_authentication!, :authenticate_admin!

  protected

  def use_signed_params
    incoming_user = nil
    found_incoming_user_by = nil

    # First try to to find an existing user by an external UUID

    if external_user_uuid.present?
      incoming_user = UserExternalUuid.find_by_uuid(external_user_uuid).try(:user)

      if incoming_user.present?
        found_incoming_user_by = "external uuid"
      end
    end

    # If that didn't pan out, try to find an existing user with a verified email
    # matching the secure params email

    if incoming_user.nil? && external_email.present?
      incoming_user = LookupUsers.by_verified_email(external_email).first

      if incoming_user.present?
        found_incoming_user_by = "external email"

        if external_user_uuid.present?
          # Go ahead and track the external UUID so can use in future
          incoming_user.external_uuids.create!(uuid: external_user_uuid)
        end
      end
    end

    if incoming_user.present?
      if signed_in? && incoming_user != current_user
        # Sign out the current user; signing in the new user will effectively sign out
        # the current user, but we choose to sign out explicitly so we can record
        # information in the current user's security log

        sign_out!(security_log_data: {type: 'different external user'})
      end

      sign_in!(incoming_user, security_log_data: {type: found_incoming_user_by})
    else
      # By providing secure params, we assume here that the site that sent this person to
      # Accounts was asking that the person either be (1) automatically logged in, (2)
      # automatically logged in on subsequent logins, or (3) directed through a partially
      # pre-populated sign up process.  If we didn't find a user to automatically log in,
      # we do not want to assume that any already-logged-in user owns this secure
      # params information.  Therefore at this point we sign out whoever is signed in.

      sign_out!(security_log_data: {type: 'new external user'}) if signed_in?

      # Save the secure params data to facilitate sign up if that's what the user
      # chooses to do

      signup_state = SignupState.create_from_trusted_data(params[:sp])
      save_signup_state(signup_state)
    end
  end

  def signed_params
    params[:sp]
  end

  def external_user_uuid
    signed_params['external_user_uuid']
  end

  def external_email
    signed_params['email']
  end

  def request_url_without_signed_params
    uri = Addressable::URI.parse(request.url || "")

    params = uri.query_values
    params.try(:delete, 'sp')
    uri.query_values = params

    uri.to_s
  end

end
