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
  uses_routine CreateIdentity

  protected

  def exec(options)
    user = nil

    if options[:username]
      user = find_or_create_by_username(options)
    elsif options[:email]
      user = find_or_create_by_email(options)
    else
      fatal_error(code: :invalid_input, message: "Must provide either email or username")
      return
    end

    if 'unclaimed' == user.state
      # If a username and password was given, set the unclaimed user's identity
      if options[:username] && options[:password]
        set_or_create_password(user, options)
      end
      outputs[:user] = user
    else
      fatal_error(code: :account_already_claimed, message: "Account has already been claimed")
      return
    end
  end


  def set_or_create_password(user, options)
    if user.identity
      run(SetPassword, user.identity, options[:password],
          options[:confirm_password], 0 # expire immediately
         )
    else
      identity = run(CreateIdentity, {
                       user_id: user.id, password: options[:password],
                       password_confirmation: options[:password_confirmation]
                     }).outputs.identity
      identity.password_expires_at = DateTime.now
      identity.save!
      user.reload # is needed in order to notice the newly created identity
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
    if user.nil?
      user = run(CreateUser,
                 state: 'unclaimed', username: options[:username],
                 ensure_no_errors: true).outputs.user
      if options[:email]
        run(AddEmailToUser, options[:email], user)
      end
    end
    return user
  end

end
