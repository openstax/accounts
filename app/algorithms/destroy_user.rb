
class DestroyUser

  include Algorithm

protected

  def exec(user)
    return if user.nil?

    # Make sure object up to date, esp before dependent destroy stuff kicks in
    user.reload
    raise Blah, user if user.person.present?
    user.destroy_original
  end

end