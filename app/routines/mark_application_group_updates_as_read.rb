# Routine for marking all given application groups' updates as read
#
# Caller provides the current application, plus an array of hashes with the following
# 2 required keys: 'id' contains the ApplicationGroup's ID and
# read_updates contains the last received value of unread_updates.

class MarkApplicationGroupUpdatesAsRead

  # This transaction needs :repeatable_read to prevent missed updates
  lev_routine transaction: :repeatable_read

  protected

  def exec(application, application_group_hashes)
    return if application.blank? || application_group_hashes.blank?

    cumulative_query = nil
    app_groups = application.application_groups
    table = app_groups.arel_table

    application_group_hashes.each do |hash|
      query = (
        table[:group_id].eq(hash['group_id'])
      ).and(
        table[:unread_updates].eq(hash['read_updates'])
      )
      cumulative_query = cumulative_query.nil? ? query : cumulative_query.or(query)
    end

    app_groups.where(
      cumulative_query
    ).update_all("unread_updates = 0") # rubocop:disable Rails/SkipsModelValidations
  end

end
