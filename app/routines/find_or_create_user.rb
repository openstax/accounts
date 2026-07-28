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
      return find_by_verified_email(options) if options[:already_verified]
      fatal_error(code: :invalid_input, message: 'An unverified email requires an external_id')
    else
      fatal_error(code: :invalid_input, message: 'Must provide external_id or email')
    end
  end

  # Only match an existing user by a VERIFIED copy of the email - an unverified duplicate
  # elsewhere isn't proof of anything. AddEmailToUser handles that duplicate (reclaiming or
  # merging it) when we go on to create/attach the email below.
  def find_by_verified_email(options)
    return nil unless options[:already_verified]
    EmailAddress.with_users.with_value(options[:email]).find_by(verified: true)&.user
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

    # An unverified email is only ever used to populate a brand-new account - if someone else
    # already has it, skip attaching it here rather than erroring the whole call.
    unless !options[:already_verified] && email_owned_by_a_different_user?(options[:email], user)
      run(AddEmailToUser, options[:email], user, already_verified: options[:already_verified])
    end

    FindOrCreateApplicationUser[options[:application].id, user.id] if options[:application].present?

    user
  end

  def email_owned_by_a_different_user?(email, user)
    return false if email.blank?

    EmailAddress.with_value(email).where.not(user_id: user.id).exists?
  end

end
