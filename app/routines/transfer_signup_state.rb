class TransferSignupState

  lev_routine

  def exec(signup_state:, user:)
    fatal_error(code: :no_signup_email) if signup_state.nil?

    run(
      AddEmailToUser, signup_state.contact_info_value,
      user, already_verified: signup_state.verified?
    )

    if signup_state && signup_state.signed?
      if signup_state.signed_external_uuid
        user.external_uuids.find_or_initialize_by(uuid: signup_state.signed_external_uuid)
      end
      user.signed_external_data = signup_state.signed_data
    end
    user.role = signup_state.role
    user.save
    transfer_errors_from(user, {type: :verbatim}, true)

    signup_state.destroy
    transfer_errors_from(signup_state, {type: :verbatim}, true)
  end
end
