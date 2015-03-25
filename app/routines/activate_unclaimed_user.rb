class ActivateUnclaimedUser

  lev_routine

  protected

  def exec(user)
    user.state = 'activated'
    user.save
    transfer_errors_from(user, {type: :verbatim})
  end

end
