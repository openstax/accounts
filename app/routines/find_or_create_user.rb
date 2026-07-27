# Find or create a new user with state "external" or "unclaimed"
#
# Given either an external_id or email address:
#   attempt to find a user with that attribute.
#   If the user is found, return the user
#     Otherwise create a new user with the given external_id or email,
#     set it's state to "external" or "unclaimed" and return that record

class FindOrCreateUser

  lev_routine

  uses_routine CreateUser, translations: { outputs: { type: :verbatim } }
  uses_routine FindOrCreateApplicationUser
  uses_routine AddEmailToUser

  protected

  def exec(options)
    # output either the found unclaimed user or a freshly created one
    outputs.user = find_user(options) || create_user(options)
  end

  # Attempt to find a user by either the external_id or email address
  def find_user(options)
    if options[:external_id].present?
      ExternalId.find_by_external_id_and_role(options[:external_id], options[:role])&.user ||
        find_by_verified_email(options)
    elsif options[:email].present?
      find_by_verified_email(options)
    else
      fatal_error(code: :invalid_input, message: 'Must provide external_id or email')
    end
  end

  # Only match an existing user by email when the caller has verified they control it - otherwise
  # any caller could take over an arbitrary existing account merely by asserting a known email
  # address. An unverified email that isn't actually in use yet still falls through to create_user,
  # same as before; an unverified email that IS already in use correctly hits the uniqueness
  # conflict in AddEmailToUser instead of silently returning someone else's account.
  def find_by_verified_email(options)
    return nil unless options[:already_verified]
    EmailAddress.with_users.find_by(value: options[:email])&.user
  end

  def create_user(options)
    # If a user has only the external_id set,
    # they can only login via this routine and can never add an email or be claimed
    state = options[:external_id].present? &&
            options[:email].blank? ? 'external' : 'unclaimed'

    user = run(CreateUser,
               state: state,
               external_id: options[:external_id],
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

    user
  end

end
