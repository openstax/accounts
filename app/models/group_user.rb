class GroupUser < ActiveRecord::Base
  #sortable :user_id

  belongs_to :user_group, :inverse_of => :group_users
  belongs_to :user, :inverse_of => :group_users

  attr_accessible :is_manager, :is_owner

  after_update :group_checks
  after_destroy :group_checks

  validates_presence_of :user, :user_group
  validates_uniqueness_of :user_id, :scope => :user_group_id

  scope :managers, where(:is_manager => true)
  scope :owners, where(:is_owner => true)

  protected

  def group_checks
    group.consistency_checks
  end
end
