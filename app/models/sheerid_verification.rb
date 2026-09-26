class SheeridVerification < ApplicationRecord
  VERIFIED = 'success'
  REJECTED = 'rejected'
  PENDING = 'docUpload'
  ERROR = 'error'
  EXPIRED_ERROR_ID = 'expiredVerification'

  validates :verification_id, presence: true
  validates :current_step, presence: true

  def verified?
    current_step == VERIFIED
  end

  def rejected?
    current_step == REJECTED
  end

  def pending?
    current_step == PENDING
  end

  def error?
    current_step == ERROR
  end

  def expired?
    error? && error_ids == [EXPIRED_ERROR_ID]
  end

  # Translate SheerID nomenclature to `User#faculty_status` nomenclature.
  # Returns the string label (not the enum's underlying integer) because
  # `User#advance_faculty_status!` looks it up in FacultyStatusLadder::RANK by
  # that string.
  def faculty_status_for_step
    case current_step
    when VERIFIED
      User::CONFIRMED_FACULTY
    when REJECTED
      User::REJECTED_BY_SHEERID
    when ERROR
      expired? ? User::SHEERID_EXPIRED : User::SHEERID_ERROR
    else
      User::PENDING_SHEERID
    end
  end

  # Persists everything SheerID told us about a verification_id, on every
  # webhook delivery -- including error and collectTeacherPersonalInfo steps,
  # which used to return before a row existed.
  def self.record_webhook!(details, verification_id:)
    verification = find_or_initialize_by(verification_id: verification_id)
    verification.email = details.email
    verification.current_step = details.current_step
    verification.first_name = details.first_name
    verification.last_name = details.last_name
    verification.organization_name = details.organization_name
    verification.error_ids = details.error_ids
    verification.rejection_reasons = details.rejection_reasons
    verification.segment = details.segment
    verification.last_response = details.raw
    verification.webhook_received_at = Time.current
    verification.webhook_count = (verification.webhook_count || 0) + 1
    verification.save!
    verification
  end
end
