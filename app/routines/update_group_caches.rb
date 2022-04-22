# Routine for updating group caches when a group_nesting is created or destroyed
#
# Caller provides the group_nesting object

class UpdateGroupCaches

  # This transaction needs :repeatable_read to prevent missed updates
  lev_routine transaction: :repeatable_read

  uses_routine AddUnreadUpdateForGroup, as: :add_unread_update

  protected

  def exec(group_nesting)
    subtree_group_ids = group_nesting.member_group.subtree_group_ids
    supertree_group_ids = group_nesting.container_group.supertree_group_ids
    tree_group_ids = (subtree_group_ids + supertree_group_ids).uniq

    # rubocop:disable Rails/SkipsModelValidations
    ApplicationGroup.where(group_id: tree_group_ids)
                    .update_all('unread_updates = unread_updates + 1')

    Group.where(id: subtree_group_ids).update_all(cached_supertree_group_ids: nil)
    Group.where(id: supertree_group_ids).update_all(cached_subtree_group_ids: nil)
    # rubocop:enable Rails/SkipsModelValidations
  end

end
