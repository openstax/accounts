class UserFromSignupState

  lev_routine express_output: :user

  protected

  def exec(signup_state)
    user = User.new
    if signup_state.trusted?
      user.role = signup_state.role
      user.full_name = signup_state.trusted_data['name']
      user.self_reported_school = signup_state.trusted_data['school']
      if signup_state.trusted_data['uuid']
        user.external_uuids.build(uuid: signup_state.trusted_data['uuid'])
      end
      user.trusted_signup_data = signup_state.trusted_data
    end
    user.save
    outputs.user = user
    transfer_errors_from(user, {type: :verbatim}, true)
  end

end
