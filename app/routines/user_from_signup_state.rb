class UserFromSignupState

  lev_routine

  protected

  def exec(signup_state)
    user = User.new
    if signup_state.trusted?
      user.role = signup_state.role
      user.full_name = signup_state.trusted_data['name']
    end
    user.save
    outputs.user = user
    transfer_errors_from(user, {type: :verbatim}, true)
  end

end
