# Routine for adding an unread update to a given user's application users
#
# Caller provides the user object

class AddUnreadUpdateForUser

  # This transaction needs :repeatable_read to prevent missed updates
  lev_routine transaction: :repeatable_read

protected

  def exec(user)
    outputs[:status] = :internal_server_error
    return if user.nil?
    # TODO: We can optimize the following query...
    # But let's not do premature optimization.
    # Maybe try an update_all with https://gist.github.com/nertzy/664645
    user.application_users.each do |app_user|
      app_user.unread_updates += 1
      app_user.save!
    end
    outputs[:status] = :ok
  end

end
