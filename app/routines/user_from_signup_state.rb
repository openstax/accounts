class UserFromSignupState

  lev_routine

  protected

  def exec(signup_state)
    outputs.user = User.new
    if signup_state.trusted?
      outputs.user.role = signup_state.role
      outputs.user.full_name = signup_state.trusted_data['name']
    end
    outputs.user.save
    transfer_errors_from(outputs.user, {type: :verbatim}, true)
  end

end
