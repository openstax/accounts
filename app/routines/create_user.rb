# Creates a user with the supplied parameters.
#
# If the :username is blank or if :ensure_no_errors is true, the routine
# will make sure that the username is available.  
#
# If :ensure_no_errors is not set, the returned user object may have errors
# and if so will not be saved.
#
class CreateUser

  ATTEMPTS = 10

  lev_routine

  protected

  def exec(inputs={})
    username = inputs[:username]

    if username.nil? || inputs[:ensure_no_errors]
      # If the number of attempts is exceeded, the user creation will fail
      for i in 1..ATTEMPTS do
        break if !username.blank? && User.where(username: username).none?
        username = "#{inputs[:username] || 'user'}#{rand(1000000)}"
      end
    end

    outputs[:user] = User.create do |user|
      user.username = username
      user.first_name = inputs[:first_name]
      user.last_name = inputs[:last_name]
      user.is_temp = true  # all users start as temp
    end

    transfer_errors_from(outputs[:user], {type: :verbatim})
  end

end