class SheeridVerification < ActiveRecord::Base

  VERIFIED = 'success'
  REJECTED = 'rejected'

  validates :verification_id, presence: true
  validates :current_step, presence: true

  def verified?
    self.current_step == VERIFIED
  end

  def rejected?
    self.current_step == REJECTED
  end

  # Translate SheerID nomenclature to `User#faculty_status` nomenclature
  def current_step_to_faculty_status
    case self.current_step
    when VERIFIED
      User.faculty_statuses[:confirmed_faculty]
    when REJECTED
      User.faculty_statuses[:rejected_faculty]
    else
      User.faculty_statuses[:pending_faculty]
    end
  end

end
