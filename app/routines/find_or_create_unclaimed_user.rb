# Find or create a new user with state "unclaimed"
#
# Given either an email address or username:
#   attempt to find a user with that attribute.
#   If the user is found, return the user
#     Otherwise create a new user with the email and username given,
#     set it's state to "unclaimed" and return that record

class FindOrCreateUnclaimedUser

  lev_routine

  uses_routine CreateUser, translations: { outputs: { type: :verbatim } }
  uses_routine AddEmailToUser
  uses_routine SetPassword

  protected

  def exec(options)
    user = if options[:email]
             find_or_create_by_email(options)
           elsif options[:username]
             find_or_create_by_username(options)
           else
             fatal_error(code: :invalid_input, message: "Must provide either email or username")
           end
    if 'unclaimed' == user.state
      outputs[:user] = user
    else
      fatal_error(code: :account_already_claimed, message: "Account has already been claimed")
    end
  end

  def find_or_create_by_email(options)
    email = EmailAddress.with_users.where(value: options[:email]).first
    if email
      return email.user
    else
      user = run(CreateUser,
                 state: 'unclaimed', username: options[:username],
                 ensure_no_errors: true).outputs.user
      run(AddEmailToUser, options[:email], user)
      return user
    end
  end

  def find_or_create_by_username(options)
    user = User.where( username: options[:username] ).first
    if !user
      user = run(CreateUser,
                 state: 'unclaimed', username: options[:username],
                 ensure_no_errors: true).outputs.user
      if options[:email]
        run(AddEmailToUser, options[:email], user)
      end
    end
    user
  end

end
