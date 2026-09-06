module Salesforce
  # Determines a user's faculty_status from signup context or from a Salesforce
  # Contact, preserving the protection rules that prevent confirmed/pending/
  # rejected statuses from being downgraded to incomplete/no_info.
  module ResolveFacultyStatus
    class UnknownFacultyVerifiedError < StandardError; end

    # Statuses that should not be overwritten by an incoming :incomplete_signup
    # or :no_faculty_info from Salesforce.
    PROTECTED_BY_INCOMPLETE_OR_NO_INFO = %w[confirmed_faculty pending_faculty rejected_faculty].freeze

    # An incoming :pending_faculty should not overwrite an existing
    # :confirmed_faculty.
    PROTECTED_BY_PENDING = %w[confirmed_faculty].freeze

    DOWNGRADE_VALUES = %w[incomplete_signup no_faculty_info].freeze

    module_function

    # Set faculty_status based on signup state (profile completion + SheerID).
    # Persists the user.
    def from_signup(user)
      if user.is_profile_complete?
        new_status = :pending_faculty
        verification = SheeridVerification.find_by(verification_id: user.sheerid_verification_id)
        new_status = verification.current_step_to_faculty_status if verification
        user.faculty_status = new_status
      else
        user.faculty_status = :incomplete_signup
      end
      user.save!
    end

    # Apply faculty_verified from an SF Contact to user, respecting the
    # protection rules. Does NOT persist (caller decides).
    def from_contact(user, sf_contact)
      faculty_verified = sf_contact.faculty_verified
      new_status =
        if faculty_verified.nil?
          'no_faculty_info'
        elsif User::VALID_FACULTY_STATUSES.include?(faculty_verified)
          faculty_verified
        else
          msg = "Unknown faculty_verified field: '#{faculty_verified}' on contact #{sf_contact.id}"
          Sentry.capture_message(msg)
          raise UnknownFacultyVerifiedError, msg
        end

      return if blocked?(user.faculty_status, new_status)

      user.faculty_status = new_status
    end

    def blocked?(current, incoming)
      current = current.to_s
      incoming = incoming.to_s
      return true if PROTECTED_BY_INCOMPLETE_OR_NO_INFO.include?(current) && DOWNGRADE_VALUES.include?(incoming)
      return true if PROTECTED_BY_PENDING.include?(current) && incoming == 'pending_faculty'
      false
    end
  end
end
