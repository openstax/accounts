class UserFromPreAuthState

  lev_routine express_output: :user

  protected

  def exec(pre_auth_state)
    user = User.new
    if pre_auth_state && pre_auth_state.signed?
      user.role = pre_auth_state.role
      user.full_name = pre_auth_state.signed_data['name']
      user.self_reported_school = pre_auth_state.signed_data['school']
      if pre_auth_state.signed_external_uuid
        user.external_uuids.build(uuid: pre_auth_state.signed_external_uuid)
      end
      user.signed_external_data = pre_auth_state.signed_data
    end
    user.save
    outputs.user = user
    transfer_errors_from(user, {type: :verbatim}, true)
  end

end
