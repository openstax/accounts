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

    sanitized_sql_query = application_groups.collect do |ag|
      ActiveRecord::Base.send(:sanitize_sql_array,
        ["WHEN ? THEN (CASE WHEN unread_updates > ? THEN unread_updates - ? ELSE 0 END)",
          ag['id'], ag['read_updates'], ag['read_updates']])
    end.join('\n')
    application.application_groups.update_all("unread_updates = CASE id #{sanitized_sql_query} ELSE unread_updates END")
  end

end
