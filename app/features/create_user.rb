
class CreateUser

  include Feature

  def exec
    User.create()
  end

end