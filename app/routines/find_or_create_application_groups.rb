# Finds or creates ApplicationGroups for the given application and group_ids.
class FindOrCreateApplicationGroups
  lev_routine

  protected

  def exec(application_id, group_ids)
    outputs.application_groups = ApplicationGroup.import(
      group_ids.map do |group_id|
        ApplicationGroup.new(application_id: application_id, group_id: group_id)
      end, on_duplicate_key_ignore: true
    ).results # This returns newly-inserted records only

    # This returns records that were already present
    existing_group_ids = group_ids - outputs.application_groups.map(&:group_id)
    outputs.application_groups += ApplicationGroup.where(
      application_id: application_id, group_id: existing_group_ids
    ).to_a
  end
end
