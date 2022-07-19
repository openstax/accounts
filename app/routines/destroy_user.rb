class DestroyUser

  lev_routine

  protected

  def exec(user)
    return if user.nil?

    # Make sure object up to date, esp before dependent destroy stuff kicks in
    user.reload

    fatal_error(code: :cannot_destroy_activated_user, data: user) if user.activated?

    user.destroy!
  end

end
