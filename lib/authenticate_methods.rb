require 'addressable/uri'

module AuthenticateMethods

  def newflow_authenticate_user!
    if signed_params.present?
      newflow_use_signed_params

      store_url(url: request_url_without_signed_params)

      if session[:user_from_signed_params]
        redirect_to newflow_login_path(request.query_parameters) and return
      elsif signed_params['role'] == 'student'
        redirect_to newflow_signup_student_path(request.query_parameters) and return
      else
        # TODO: this will change when we create the Educator flow
        redirect_to newflow_signup_path(request.query_parameters) and return
      end
    end

    return if signed_in?

    # Drop signed params from where we will go back after log in so we don't
    # try to use them again.
    store_url(url: request_url_without_signed_params)

    permitted_params = params.permit(:client_id, :signup_at, :go, :no_signup, :newflow, :bpff).to_h

    redirect_to(newflow_login_path(permitted_params))
  end

  def authenticate_user!
    use_signed_params if signed_params.present?

    return if signed_in?

    # Drop signed params from where we will go back after log in so we don't
    # try to use them again.
    store_url(url: request_url_without_signed_params)

    if pre_auth_state && pre_auth_state.signed_student? && pre_auth_state_email_available?
      redirect_to main_app.signup_path
    else
      # Note that the following means that users must arrive with the newflow param
      # when they arrive at the oauth_authorization path in order for them to be redirected to the
      # newflow login instead of the old login page.
      # We might want to undo this when we release the new flow.
      permitted_params = params.permit(:client_id, :signup_at, :go, :no_signup, :newflow).to_h
      destination =  params[:newflow].present? ? newflow_login_path(permitted_params) : main_app.login_path(permitted_params)

      redirect_to(destination)
    end
  end

  def authenticate_admin!
    return if current_user.is_administrator?
    return head(:forbidden) if signed_in?
    store_url
    redirect_to main_app.login_path(params.permit(:client_id).to_h)
  end

  # Doorkeeper controllers define authenticate_admin!, so we need another name
  alias_method :admin_authentication!, :authenticate_admin!

  protected #################

  # When the external site provides signed params they're
  # requesting the person either be
  # (1) automatically logged in if their UUID is known to us, or
  # (2) allowed to log in or sign up where we pre-populate some fields using
  #     the signed data and remember their external UUID so that future requests
  #     with signed params with this UUID can be automatically logged in
  def use_signed_params
    auto_login_external_user || prepare_for_new_external_user
  end

  # When the external site provides signed params they're
  # requesting the person either be
  # (1) automatically logged in if their UUID is known to us, or
  # (2) allowed to log in or sign up where we pre-populate some fields using
  #     the signed data and remember their external UUID so that future requests
  #     with signed params with this UUID can be automatically logged in
  def newflow_use_signed_params
    auto_login_external_user || newflow_prepare_for_new_external_user
  end

  def newflow_prepare_for_new_external_user
    # If we didn't find a user with a linked account to automatically log in,
    # we do not want to assume that any already-logged-in user owns this signed
    # params information.
    # Therefore at this point we sign out whoever is signed in.

    sign_out!(security_log_data: {type: 'new external user'}) if signed_in?

    # Save the signed params data to facilitate either sign in or up
    # depending on the user's choices
    user = Newflow::FindOrCreateUserFromSignedParams.call(signed_params).outputs.user
    session[:user_from_signed_params] = user
  end

  def pre_auth_state_email_available?
    LookupUsers.by_verified_email(
      pre_auth_state.contact_info_value
    ).none?
  end


  def auto_login_external_user
    return false unless external_user_uuid.present?

    # Try to to find an existing user who has a matching external UUID
    # which indicates the account has been linked before
    # if found, we trust it and sign the user in automatically
    incoming_user = UserExternalUuid.find_by_uuid(external_user_uuid).try(:user)
    return false if incoming_user.nil?

    if signed_in? && incoming_user != current_user
      # Sign out the current user; signing in the new user will effectively sign out
      # the current user, but we choose to sign out explicitly so we can record
      # information in the current user's security log

      sign_out!(security_log_data: {type: 'different external user'})
    end

    sign_in!(incoming_user, security_log_data: {type: 'external uuid'})
    true
  end

  def prepare_for_new_external_user
    # If we didn't find a user with a linked account to automatically log in,
    # we do not want to assume that any already-logged-in user owns this signed
    # params information.
    # Therefore at this point we sign out whoever is signed in.

    sign_out!(security_log_data: {type: 'new external user'}) if signed_in?

    # Save the signed params data to facilitate either sign in or up
    # depending on the user's choices
    pre_auth_state = PreAuthState.create_from_signed_data(signed_params)
    save_pre_auth_state(pre_auth_state)
  end

  def signed_params
    params[:sp].present? ? params[:sp].permit!.to_h.with_indifferent_access : {}
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
