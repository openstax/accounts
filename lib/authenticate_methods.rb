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


  # When the external site provides secure params the're
  # requesting the person either be
  # (1) automatically logged in if their UUID is known to us
  # (2) Their UUID is remembered after they login so they're automatically logged in on subsequent visits
  # (3) directed through a partially pre-populated sign up process, with the UUID being remembered at the end.
  def use_signed_params
    auto_login_external_user || prepare_new_external_user_signup
  end

  def auto_login_external_user
    return false unless external_user_uuid.present?

    incoming_user = nil
    found_incoming_user_by = nil

    # Try to to find an existing user who has a matching external UUID
    # which indicates the account has been linked before
    # if found, we trust it and sign the user in automatically
    incoming_user = UserExternalUuid.find_by_uuid(external_user_uuid).try(:user)
    if incoming_user.present?
      sign_out!(security_log_data: {type: 'new external user'}) if signed_in?
      sign_in!(incoming_user, security_log_data: {type: 'external uuid'})
      return true
    end
    false
  end

  def prepare_new_external_user_signup
    # If we didn't find a user with a linked account to automatically log in,
    # we do not want to assume that any already-logged-in user owns this secure
    # params information.  Therefore at this point we sign out whoever is signed in.
    sign_out!(security_log_data: {type: 'new external user'}) if signed_in?

    # Save the secure params data to facilitate sign up if that's what the user
    # chooses to do
    signup_state = SignupState.create_from_trusted_data(params[:sp])
    save_signup_state(signup_state)
  end


  def signed_params
    params[:sp]
  end

  def external_user_uuid
    signed_params['uuid']
  end

  def external_email
    signed_params['email']
  end

  def request_url_without_signed_params
    uri = Addressable::URI.parse(request.url || "")

    params = uri.query_values
    params.delete_if{|key, _| key.starts_with?("sp[")} if params.present?
    uri.query_values = params

    uri.to_s
  end

end
