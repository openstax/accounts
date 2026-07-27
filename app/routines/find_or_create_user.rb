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
  uses_routine MergeUnclaimedUsers

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
      return find_by_verified_email(options) if options[:already_verified]
      fatal_error(code: :invalid_input, message: 'An unverified email requires an external_id')
    else
      fatal_error(code: :invalid_input, message: 'Must provide external_id or email')
    end
  end

  # A verified email match against an activated user's unverified secondary contact isn't
  # proof of anything - leave that real account alone (nil = no match, AddEmailToUser will
  # reclaim the stale contact anyway). Against an unclaimed placeholder, claim it instead.
  def find_by_verified_email(options)
    return nil unless options[:already_verified]
    contact_info = EmailAddress.with_users.find_by(value: options[:email])
    return nil unless contact_info
    return contact_info.user if contact_info.verified?
    return nil if contact_info.user.activated?

    create_user(options, replacing: contact_info.user)
  end

  def create_user(options, replacing: nil)
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

    # Claim the placeholder before attaching the email, so its value is free to reattach
    run(MergeUnclaimedUsers, dying_user: replacing, living_user: user) if replacing

    # routine is smart and gracefully handles case of missing options[:email]
    run(AddEmailToUser, options[:email], user, already_verified: options[:already_verified])

    FindOrCreateApplicationUser[options[:application].id, user.id] if options[:application].present?

    user
  end

end
