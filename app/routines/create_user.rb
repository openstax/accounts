# Creates a user with the supplied parameters.
#
# If :ensure_no_errors is true, the routine will make sure that the 
# username is available (blank/nil usernames are allowed in this case)
#
# If :ensure_no_errors is not set, the returned user object may have errors
# and if so will not be saved.
class CreateUser

  USERNAME_ATTEMPTS = 10

  lev_routine

  protected

  def exec(options = {})
    username = options[:username]

    if options[:ensure_no_errors]
      username = get_valid_username(options[:username])

      # If the number of attempts is exceeded, the user creation will fail
      for i in 1..USERNAME_ATTEMPTS do
        break if User.where('LOWER(username) = ?', username).none?
        username = get_valid_username(options[:username])
        username = randomify_username(username)
      end
    end

    outputs[:user] = User.create do |user|
      user.username = username
      user.first_name = options[:first_name]
      user.last_name = options[:last_name]
      user.full_name = options[:full_name]
      user.title = options[:title]
      user.is_temp = true  # all users start as temp
    end

    transfer_errors_from(outputs[:user], {type: :verbatim})
  end

  # Returns a valid, though possibly non-unique, username
  def get_valid_username(base)
    base = randomify_username(base) if base.blank?

    # Go ahead and sanitize the username knowing that User.create will
    # expect it to adhere to certain rules on length and content.
    base = base.gsub(User::USERNAME_DISCARDED_CHAR_REGEX, '')
               .slice(0..User::USERNAME_MAX_LENGTH - 1).downcase
  end

  def randomify_username(base)
    base = 'user' if base.blank?
    "#{base}#{rand(1000000)}"
  end

end
