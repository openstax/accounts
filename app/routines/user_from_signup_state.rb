class UserFromSignupState

  lev_routine express_output: :user

  protected

  def exec(signup_state)
    user = User.new
    if signup_state && signup_state.signed?
      user.role = signup_state.role
      user.full_name = signup_state.signed_data['name']
      user.self_reported_school = signup_state.signed_data['school']
      if signup_state.signed_external_uuid
        user.external_uuids.build(uuid: signup_state.signed_external_uuid)
      end
      user.signed_external_data = signup_state.signed_data
    end
    user.save
    outputs.user = user
    transfer_errors_from(user, {type: :verbatim}, true)
  end

end
