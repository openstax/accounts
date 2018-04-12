# Creates a user with the supplied parameters.
#
# If :ensure_no_errors is true, the routine will make sure that the username is available or nil
#
# If :ensure_no_errors is not set, the returned user object may have errors
# that will cause this routine to fail
class CreateUser

  lev_routine express_output: :user

  protected

  def exec(state:, username: nil,
           title: nil, first_name: nil, last_name: nil, suffix: nil,
           salesforce_contact_id: nil, faculty_status: nil, role: nil,
           school_type: nil, ensure_no_errors: false)

    username = generate_unique_valid_username(username) if ensure_no_errors
    create_method = ensure_no_errors ? :create! : :create

    outputs[:user] = User.send(create_method) do |user|
      user.state = state
      user.username = username
      user.first_name = first_name
      user.last_name = last_name
      user.title = title
      user.suffix = suffix
      user.salesforce_contact_id = salesforce_contact_id
      user.faculty_status = faculty_status || :no_faculty_info
      user.role = role || :unknown_role
      user.school_type = school_type || :unknown_school_type
    end

    transfer_errors_from(outputs[:user], type: :verbatim)
  end

  def generate_unique_valid_username(username)
    return username if User.username_is_valid?(username)

    username_max_attempts = 10

    username_max_attempts.times do
      username = User.create_random_username(base: "user", num_digits_in_suffix: 7)
      return username if User.username_is_valid?(username)
    end

    raise "could not create a unique username after #{username_max_attempts} tries"
  end

end
