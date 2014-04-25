# Routine for marking all given application users' updates as read
#
# Caller provides the current application, plus a hash where the keys are
# ApplicationUser ID's and the values are the last seen value of unread_updates

class MarkApplicationUsersUpdatesAsRead

  # This transaction needs :repeatable_read to prevent missed updates
  lev_routine transaction: :repeatable_read

protected

  def exec(application, application_users)
    outputs[:status] = :internal_server_error
    return if application.nil? || application_users.nil?
    # TODO: We can optimize the following queries...
    # But let's not do premature optimization.
    # Maybe try an update_all with https://gist.github.com/nertzy/664645
    # Also, can use find_in_batches if we end up with too many records
    # (and the select query runs out of memory).
    ids = application_users.keys
    ApplicationUser.where{id.in ids}.each do |app_user|
      raise SecurityTransgression if app_user.application != application
      last_unread_count = application_users[app_user.id]
      new_unread_count = app_user.unread_updates - last_unread_count
      app_user.unread_updates = [new_unread_count, 0].max
      app_user.save!
    end
    outputs[:status] = :ok
  end

end
