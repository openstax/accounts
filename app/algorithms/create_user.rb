
# Creates a user with the supplied parameters.
#
# If the :username is blank or if :ensure_no_errors is true, the algorithm
# will make sure that the username is available.  
#
# If :ensure_no_errors is not set, the returned user object may have errors
# and if so will not be saved.
#
class CreateUser

  include Lev::Routine

protected

  def exec(inputs={})
    username = inputs[:username]

    if username.nil? || inputs[:ensure_no_errors]
      loop do 
        username = "#{inputs[:username] || 'user'}#{rand(1000000)}"
        break if User.where(username: username).none?
      end
    end

    results[:user] = User.create do |user|
      user.username = username
      user.first_name = inputs[:first_name]
      user.last_name = inputs[:last_name]
      user.is_temp = true  # all users start as temp
    end

    transfer_errors_from(results[:user])
  end

end