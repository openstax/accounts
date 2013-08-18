
class CreateUser

  include Algorithm

  def exec
    User.create()
  end

end