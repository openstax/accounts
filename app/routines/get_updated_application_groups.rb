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

    visible_group_ids = Group.joins(:owners => :application_users)
      .joins(:members => :application_users)
      .where{(is_public.eq true) |\
             (owners.application_users.application_id.eq my{application.id}) |\
             (members.application_users.application_id.eq my{application.id})}
      .collect{|g| g.subtree_group_ids}.flatten.uniq
    application_groups = FindOrCreateApplicationGroups.call(application_id, visible_group_ids)
                                                      .outputs.application_groups
    outputs[:application_groups] = application_groups.select{|ag| ag.unread_updates > 0}
  end

end
