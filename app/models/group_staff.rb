class GroupStaff < ActiveRecord::Base
  #sortable :user_id

  belongs_to :group, inverse_of: :group_staffs
  belongs_to :user, inverse_of: :group_staffs

  validates_presence_of :group, :user, :role
  validates_uniqueness_of :user_id, scope: [:group_id, :role]

  scope :viewers, lambda { where(role: 'viewer') }
  scope :managers, lambda { where(role: 'manager') }
  scope :owners, lambda { where(role: 'owner') }
end
