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
    verification = find_or_create_for(verification_id, details.current_step)

    verification.with_lock do
      verification.update!(
        email: details.email,
        current_step: details.current_step,
        first_name: details.first_name,
        last_name: details.last_name,
        organization_name: details.organization_name,
        error_ids: details.error_ids,
        rejection_reasons: details.rejection_reasons,
        segment: details.segment,
        last_response: details.raw,
        webhook_received_at: Time.current,
        webhook_count: verification.webhook_count + 1
      )
    end

    verification
  end

  # SheerID retries and can deliver the same webhook twice at once; the unique
  # index turns the loser of that race into a RecordNotUnique we can recover from.
  def self.find_or_create_for(verification_id, current_step)
    find_or_create_by!(verification_id: verification_id) { |v| v.current_step = current_step }
  rescue ActiveRecord::RecordNotUnique
    find_by!(verification_id: verification_id)
  end
  private_class_method :find_or_create_for
end
