class GroupNesting < ActiveRecord::Base

  belongs_to :container_group, class_name: 'Group', inverse_of: :member_group_nestings
  belongs_to :member_group, class_name: 'Group', inverse_of: :container_group_nesting

  validates_presence_of :container_group, :member_group
  validates_uniqueness_of :member_group_id
  validate :no_loops, on: :create

  before_create :invalidate_cached_trees, :add_unread_update
  before_destroy :invalidate_cached_trees, :add_unread_update

  protected

  def add_unread_update
    container_group.add_unread_update
  end

  def no_loops
    return if member_group.nil? ||\
              !member_group.subtree_group_ids.include?(container_group_id)
    errors.add(:base, 'would create a loop') if errors[:base].blank?
    false
  end

  def invalidate_cached_trees
    container_group.invalidate_cached_subtrees
    member_group.invalidate_cached_supertrees
  end

end
