class GroupUser < ActiveRecord::Base
  #sortable :user_id

  belongs_to :group, inverse_of: :group_users
  belongs_to :user, inverse_of: :group_users

  validates_presence_of :user, :group, :role
  validates_uniqueness_of :user_id, scope: [:group_id, :role]

  scope :members, lambda { where(role: 'member') }
  scope :viewers, lambda { where(role: 'viewer') }
  scope :managers, lambda { where(role: 'manager') }
  scope :owners, lambda { where(role: 'owner') }
end
