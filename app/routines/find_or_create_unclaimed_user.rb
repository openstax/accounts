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
    unless options[:email] || options[:username]
      fatal_error(code: :invalid_input, message: "Must provide email or username")
    end

    user = find_user(options)

    # output either the found unclaimed user or a freshly created one
    outputs[:user] = user || create_user(options)
  end

  def create_user(options)
    user = run(CreateUser,
               state: 'unclaimed', username: options[:username],
               first_name: options[:first_name],
               last_name: options[:last_name], full_name: options[:full_name],
               ensure_no_errors: true).outputs.user

    # routine is smart and gracefully handles case of missing options[:email]
    run(AddEmailToUser, options[:email], user)

    if options[:password]
      identity = run(CreateIdentity, {
                       user_id: user.id,
                       password: options[:password],
                       password_confirmation: options[:password]
                     }).outputs.identity
      # set the identity's password as expired, as soon as the user logs in
      # they'll be prompted to reset it
      identity.password_expires_at = DateTime.now
      identity.save!
      user.authentications.create!(
        # TODO review this creation of authentication (otherwise only in SessionsCreate)
        provider: 'identity', uid: identity.id.to_s
      )
    end

    user
  end

  # Attempt to find a user by either the username or email address
  def find_user(options)
    user = nil
    if options[:username]
      user = User.where(username: options[:username]).first
    end
    if !user && options[:email]
      email = EmailAddress.with_users.where(value: options[:email]).first
      if email
        user = email.user
      end
    end
    user
  end



end
