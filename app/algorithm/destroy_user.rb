
class DestroyUser

  include Algorithm

  def exec(user)
    return if user.nil?

    raise Blah, user if user.person.present?

    user.destroy
  end

end