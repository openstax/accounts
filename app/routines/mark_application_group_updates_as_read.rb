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

    application.application_groups.where do
      cumulative_query = nil
      application_group_hashes.each do |hash|
        query = (group_id == hash['group_id']) & (unread_updates == hash['read_updates'])
        cumulative_query = cumulative_query.nil? ? query : cumulative_query | query
      end
      cumulative_query
    end.update_all("unread_updates = 0")
  end

end
