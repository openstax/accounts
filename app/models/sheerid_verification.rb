class SheeridVerification < ApplicationRecord
  validates :verification_id, presence: true
  validates :current_step, presence: true

  VERIFIED = 'success'
  REJECTED = 'rejected'

  def verified?
    self.current_step == VERIFIED
  end

  def rejected?
    self.current_step == REJECTED
  end

  # Translate SheerID nomenclature to `User#faculty_status` nomenclature
  def current_step_to_faculty_status
    case self.current_step
    when self.current_step == 'success'
      User.faculty_statuses[:confirmed_faculty]
    when self.current_step == 'rejected'
      User.faculty_statuses[:rejected_faculty]
    else
      User.faculty_statuses[:pending_faculty]
    end
  end

end
