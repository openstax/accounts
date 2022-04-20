class GroupNesting < ApplicationRecord

  belongs_to :container_group, class_name: 'Group', inverse_of: :member_group_nestings
  belongs_to :member_group, class_name: 'Group', inverse_of: :container_group_nesting

  validates :container_group, :member_group, presence: true
  validates :member_group_id, uniqueness: true
  validate :no_loops, on: :create

  before_create :update_group_caches
  before_destroy :update_group_caches

  protected

  def no_loops
    return if member_group.nil? || !member_group.subtree_group_ids.include?(container_group_id)
    errors.add(:base, 'would create a loop') if errors[:base].blank?
    false
  end

  def update_group_caches
    # Returns false if the update fails (aborting the save transaction)
    UpdateGroupCaches.call(self).errors.none?
  end

end
