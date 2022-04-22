# Routine for marking all given application users' updates as read
#
# Caller provides the current application, plus an array of hashes with the following
# 2 required keys: 'id' contains the ApplicationUser's ID and
# read_updates contains the last received value of unread_updates.

class MarkApplicationUserUpdatesAsRead

  # This transaction needs :repeatable_read to prevent missed updates
  lev_routine transaction: :repeatable_read

  protected

  def exec(application, application_user_hashes)
    return if application.blank? || application_user_hashes.blank?

    app_users = application.application_users
    table = app_users.arel_table

    cumulative_query = nil

    application_user_hashes.each do |hash|
      query = (
        table[:user_id].eq(hash['user_id'])
      ).and(
        table[:unread_updates].eq(hash['read_updates'])
      )
      cumulative_query = cumulative_query.nil? ? query : cumulative_query.or(query)
    end

    app_users.where(
      cumulative_query
    ).update_all("unread_updates = 0") # rubocop:disable Rails/SkipsModelValidations
  end

end
