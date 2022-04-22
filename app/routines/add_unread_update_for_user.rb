# Routine for adding an unread update to a given user's application users
#
# Caller provides the user object

class AddUnreadUpdateForUser

  # This transaction needs :repeatable_read to prevent missed updates
  lev_routine transaction: :repeatable_read

  protected

  def exec(user)
    return if user.nil?
    # rubocop:disable Rails/SkipsModelValidations
    user.application_users.update_all('unread_updates = unread_updates + 1')
    # rubocop:enable Rails/SkipsModelValidations
  end

end
