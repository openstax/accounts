
# Not called directly by users, so should just work (don't get validation errors)
class CreateUser

  include Algorithm

protected

  def exec(inputs={})
    inputs[:username] ||= 'user'
    username = inputs[:username]

    while username == 'user' || User.where(username: username).any? do
      username = "#{inputs[:username]}#{rand(1000000)}"
    end 

    User.create! do |user|
      user.username = username
    end
  end

end