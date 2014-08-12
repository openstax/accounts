# Routine for marking all given application users' updates as read
#
# Caller provides the current application, plus an array of hashes with the following
# 2 required keys: 'id' contains the ApplicationUser's ID and unread_updates contains
# the last received value of unread_updates.

class MarkApplicationUsersUpdatesAsRead

  # This transaction needs :repeatable_read to prevent missed updates
  lev_routine transaction: :repeatable_read

  protected

  def exec(application, application_users)
    return if application.nil? || application_users.nil?

    sanitized_sql_query = application_users.collect do |au|
      ActiveRecord::Base.send(:sanitize_sql_array,
        ["WHEN ? THEN (CASE WHEN unread_updates > ? THEN unread_updates - ? ELSE 0 END)",
          au['id'], au['read_updates'], au['read_updates']])
    end.join('\n')
    application.application_users.update_all("unread_updates = CASE id #{sanitized_sql_query} ELSE unread_updates END")
  end

end
