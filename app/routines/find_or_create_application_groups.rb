# Finds or creates ApplicationGroups for the given application and group_ids.
class FindOrCreateApplicationGroups

  lev_routine

  protected

  def exec(application_id, group_ids)
    application_groups = ApplicationGroup.where(application_id: application_id,
                                                group_id: group_ids)
                                         .preload(:group).to_a
    ag_group_ids = application_groups.collect{|ag| ag.group_id}

    # There might be a way to make this more efficient
    group_ids.each do |group_id|
      unless ag_group_ids.include?(group_id)
        application_group = ApplicationGroup.create do |app_group|
          app_group.application_id = application_id
          app_group.group_id = group_id
          app_group.save!
        end
        application_groups << application_group
      end
    end

    outputs[:application_groups] = application_groups
  end

end
