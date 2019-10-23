# Transfers email address (with `AddEmailToUser`), `verified` status, and  `role` information
# from PreAuthState to the user.
class TransferPreAuthState

  lev_routine

  def exec(pre_auth_state:, user:)
    fatal_error(code: :no_signup_email) if pre_auth_state.nil?

    run(
      AddEmailToUser, pre_auth_state.contact_info_value,
      user, already_verified: pre_auth_state.is_contact_info_verified?
    )

    if pre_auth_state && pre_auth_state.signed?
      if pre_auth_state.signed_external_uuid
        user.external_uuids.find_or_initialize_by(uuid: pre_auth_state.signed_external_uuid)
      end
      user.signed_external_data = pre_auth_state.signed_data
    end
    user.role = pre_auth_state.role
    user.save
    transfer_errors_from(user, {type: :verbatim}, true)

    pre_auth_state.destroy
    transfer_errors_from(pre_auth_state, {type: :verbatim}, true)
  end
end
