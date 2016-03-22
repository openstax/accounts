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

  def exec(username:, title: nil, first_name: nil, last_name: nil,
           suffix: nil, full_name: nil, state:, ensure_no_errors: false)

    original_username = username

    if ensure_no_errors
      username = get_valid_username(original_username)

      # If the number of attempts is exceeded, the user creation will fail
      for i in 1..USERNAME_ATTEMPTS do
        break if User.where('LOWER(username) = ?', username).none?  # TODO squeel this
        username = get_valid_username(original_username)
        username = randomify_username(username)
      end
    end

    outputs[:user] = User.create do |user|
      user.username = username
      user.first_name = first_name.present? ? first_name : guessed_first_name(full_name)
      user.last_name = last_name.present? ? last_name : guessed_last_name(full_name)
      user.title = title
      user.suffix = suffix
      user.state = state
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

  def guessed_first_name(full_name)
    return nil if full_name.blank?
    full_name.split("\s")[0]
  end

  def guessed_last_name(full_name)
    return nil if full_name.blank?
    full_name.split("\s").drop(1).join(' ')
  end

end
