class SheeridVerification < ApplicationRecord
  VERIFIED = 'success'
  REJECTED = 'rejected'
  PENDING = 'docUpload'
  ERROR = 'error'

  validates :verification_id, presence: true
  validates :current_step, presence: true

  def verified?
    self.current_step == VERIFIED
  end

  def rejected?
    self.current_step == REJECTED
  end

  def pending?
    self.current_step == PENDING
  end

  def error?
    self.current_step == ERROR
  end

  # Translate SheerID nomenclature to `User#faculty_status` nomenclature
  def current_step_to_faculty_status
    case self.current_step
    when VERIFIED
      User.faculty_statuses[:confirmed_faculty]
    when REJECTED || ERROR
      User.faculty_statuses[:rejected_by_sheerid]
    when PENDING
      User.faculty_statuses[:pending_sheerid]
    else
      User.faculty_statuses[:pending_faculty]
    end
  end

end
