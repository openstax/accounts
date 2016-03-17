class DestroyUser

  lev_routine

  uses_routine DestroyWhenAssociationEmpty

  protected

  def exec(user)
    return if user.nil?

    # Make sure object up to date, esp before dependent destroy stuff kicks in
    user.reload

    fatal_error(code: :cannot_destroy_activated_user, data: user) if user.is_activated?

    user.destroy_original
  end

end
