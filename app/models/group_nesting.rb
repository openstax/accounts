class GroupNesting < ActiveRecord::Base
  belongs_to :container_group, class_name: 'Group', inverse_of: :member_group_nestings
  belongs_to :member_group, class_name: 'Group', inverse_of: :container_group_nestings

  validates_presence_of :container_group, :member_group
  validates_uniqueness_of :member_group_id, scope: :container_group_id

  before_save :invalidate_cached_group_ids
  before_destroy :invalidate_cached_group_ids

  protected

  def invalidate_cached_group_ids
    Group.where(id: container_group.container_group_ids)
         .update_all(cached_member_group_ids: nil)
    Group.where(id: member_group.member_group_ids)
         .update_all(cached_container_group_ids: nil)
  end
end
