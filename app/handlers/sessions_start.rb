class SessionsStart

  lev_handler

  protected

  def authorized?
    true
  end

  def handle

    return if secure_params.blank? # nothing to do unless we have 'em

    # verify our secure params are actually secure
    unless OpenStax::Api::Params.signature_and_timestamp_valid?(
             params: secure_params,
             secret: ::Doorkeeper::Application.find_by_uid!(params[:client_id]).secret)

      Rails.logger.warn "Invalid signature for trusted parameters"
      fatal_error(code: :invalid_secure_params, offending_inputs: [:sp])
    end

    # First try to to find an existing user

    user = nil

    uuid_link = UserExternalUuid.find_by_uuid(secure_params['external_user_uuid'])
    if uuid_link.present?
      user = uuid_link.user
    elsif secure_params['email'] # maybe there's a verified email that matches?
      user = LookupUsers.by_verified_email(secure_params['email']).first
      if user && secure_params['external_user_uuid']
        user.external_uuids.create!(uuid: secure_params['external_user_uuid'])
      end
    end

    if user
      session_management.sign_in!(user)
      outputs[:user] = user
    else
      signup_state = SignupState.create_from_trusted_data(params[:sp])
      session_management.session[:signup_role] = signup_state.role
      session_management.save_signup_state(signup_state)
      outputs[:signup_state] = signup_state
    end

  end

  def secure_params
    params[:sp]
  end

  def session_management
    options[:session_management]
  end

  def signup_state
    options[:signup_state]
  end
end
