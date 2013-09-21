
class DestroyUser

  include Lev::Algorithm

protected

  def exec(user)
    return if user.nil?

    # Make sure object up to date, esp before dependent destroy stuff kicks in
    user.reload
    raise_error :cannot_destroy_non_temp_user if !user.is_temp
    user.destroy_original
    run(DestroyWhenAssociationEmpty, user.person, :users)
  end

end