class SheeridVerification < ActiveRecord::Base
  VERIFIED = 'success'
  REJECTED = 'rejected'

  validates :verification_id, presence: true
  validates :email, presence: true
  validates :current_step, presence: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :organization_name, presence: true

  def verified?
    self.current_step == VERIFIED
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
