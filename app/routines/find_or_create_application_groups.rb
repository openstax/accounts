# Finds or creates ApplicationGroups for the given application and group_ids.
class FindOrCreateApplicationGroups

  lev_routine

  protected

  def exec(application_id, group_ids)
    application_groups = ApplicationGroup.where(application_id: application_id, group_id: group_ids)
                                         .preload(:group).to_a
    ag_group_ids = application_groups.map(&:group_id)

    # There might be a way to make this more efficient
    group_ids.each do |group_id|
      unless ag_group_ids.include?(group_id)
        application_groups << ApplicationGroup.create!(application_id: application_id,
                                                       group_id: group_id)
      end
    end

    outputs[:application_groups] = application_groups
  end

end
