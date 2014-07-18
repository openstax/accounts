class GroupGroup < ActiveRecord::Base
  belongs_to :permitter_group, class_name: 'Group', inverse_of: :permitted_group_groups
  belongs_to :permitted_group, class_name: 'Group', inverse_of: :permitter_group_groups

  validates_presence_of :permitter_group, :permitted_group, :role
  validates_uniqueness_of :permitted_group_id, scope: [:permitter_group_id, :role]
  validate :no_nested_groups

  scope :viewers, lambda { where(role: 'viewer') }
  scope :managers, lambda { where(role: 'manager') }
  scope :owners, lambda { where(role: 'owner') }

  protected

  def no_nested_groups
    return unless role == 'member'
    errors.add(:role, 'is not an allowed role')
    false
  end
end
