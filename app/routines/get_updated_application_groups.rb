# Routine for listing groups visible to a certain app
#
# Caller provides the Doorkeeper::Application

class GetUpdatedApplicationGroups

  # This transaction needs :repeatable_read to prevent missed updates
  # in case 2 groups are updated at the same time as this API is called
  # Actually, ActiveRecord must be the one using :repeatable_read
  # (true by default for MySQL, false by default for PostgreSQL)
  lev_routine transaction: :repeatable_read

  protected

  def exec(application)
    return if application.nil?

    group = Group.left_joins(owners: :application_users, members: :application_users)

    visible_group_ids = group
      .where(is_public: true)
      .or(
        group.where(application_users: { application_id: 1})
      ).or(
        group.where(application_users_users: { application_id: 1})
      )
      .collect{|g| g.subtree_group_ids}.flatten.uniq
    application_groups = FindOrCreateApplicationGroups.call(application.id, visible_group_ids)
                                                      .outputs.application_groups
    outputs[:application_groups] = application_groups.select{|ag| ag.unread_updates > 0}
  end

end
