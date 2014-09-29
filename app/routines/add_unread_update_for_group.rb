# Routine for adding an unread update to a given group's application groups
#
# Caller provides the group object

class AddUnreadUpdateForGroup

  # This transaction needs :repeatable_read to prevent missed updates
  lev_routine transaction: :repeatable_read

  protected

  def exec(group)
    return if group.nil?

    group.application_groups.update_all('unread_updates = unread_updates + 1')
  end

end
