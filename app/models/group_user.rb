class GroupUser < ActiveRecord::Base
  #sortable :user_id

  # Access Levels
  # Higher levels include all the levels below
  # So an owner is always a manager, etc
  OWNER = 2
  MANAGER = 1
  MEMBER = 0

  belongs_to :user_group, inverse_of: :group_users
  belongs_to :user, inverse_of: :group_users

  attr_accessible :access_level

  after_update :group_maintenance
  after_destroy :group_maintenance

  validates_presence_of :user, :user_group
  validates_uniqueness_of :user, scope: :user_group

  scope :owners, lambda {where{access_level.gt_eq OWNER}}
  scope :managers, lambda {where{access_level.gt_eq MANAGER}}

  def is_owner?
    access_level >= OWNER
  end

  def is_manager?
    access_level >= MANAGER
  end

  def access_level_string
    ['none', 'member', 'manager', 'owner'][access_level + 1]
  end

  protected

  def group_maintenance
    group.maintenance
  end
end
