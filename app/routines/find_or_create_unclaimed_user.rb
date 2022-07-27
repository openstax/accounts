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
  uses_routine FindOrCreateApplicationUser
  uses_routine AddEmailToUser
  uses_routine CreateIdentity

  protected

  def exec(options)
    # output either the found unclaimed user or a freshly created one
    outputs.user = find_user(options) || create_user(options)
  end

  # Attempt to find a user by either the external_id, username, or email address
  def find_user(options)
    if options[:external_id].present?
      User.find_by(external_id: options[:external_id])
    elsif options[:username].present?
      User.find_by(username: options[:username])
    elsif options[:email].present?
      EmailAddress.verified.with_users.find_by(value: options[:email])&.user
    else
      fatal_error(code: :invalid_input, message: 'Must provide external_id, username, or email')
    end
  end

  def create_user(options)
    # If a user has only the external_id set,
    # they can only login via this routine and can never add an email or username or be claimed
    state = options[:external_id].present? &&
            options[:username].blank? &&
            options[:email].blank? ? 'external' : 'unclaimed'

    user = run(CreateUser,
               state: state,
               external_id: options[:external_id],
               username: options[:username],
               first_name: options[:first_name],
               last_name: options[:last_name],
               salesforce_contact_id: options[:salesforce_contact_id],
               faculty_status: options[:faculty_status],
               role: options[:role],
               school_type: options[:school_type],
               is_test: options[:is_test],
               ensure_no_errors: true).outputs.user

    # routine is smart and gracefully handles case of missing options[:email]
    run(AddEmailToUser, options[:email], user, already_verified: options[:already_verified])

    FindOrCreateApplicationUser[options[:application].id, user.id] if options[:application].present?

    if options[:password].present?
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

end
