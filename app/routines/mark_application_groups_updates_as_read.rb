# Routine for marking all given application groups' updates as read
#
# Caller provides the current application, plus an array of hashes with the following
# 2 required keys: 'id' contains the ApplicationGroup's ID and unread_updates contains
# the last received value of unread_updates.

class MarkApplicationGroupsUpdatesAsRead

  # This transaction needs :repeatable_read to prevent missed updates
  lev_routine transaction: :repeatable_read

  protected

  def exec(application, application_groups)
    return if application.nil? || application_groups.nil?

    sql_query = application_groups.collect{|au| "WHEN #{au['id']} THEN (CASE WHEN unread_updates > #{au['read_updates']} THEN unread_updates - #{au['read_updates']} ELSE 0 END)"}.join('\n')
    ApplicationGroup.update_all("unread_updates = CASE id #{sql_query} END;")
  end

end
