# Finds or creates ApplicationGroups for the given application and group_ids.
class FindOrCreateApplicationGroups
  lev_routine transaction: :read_committed

  protected

  def exec(application_id, group_ids)
    outputs.application_groups = ApplicationGroup.where(
      application_id: application_id, group_id: group_ids
    ).to_a

    # Insert missing records
    # Returns newly-inserted records only
    # We could run this as the first query, but it would cause the id sequence to autoincrement
    # by the number of group_ids every time this routine is called
    # We can still do that if we switch the primary key to a uuid column
    missing_group_ids = group_ids - outputs.application_groups.map(&:group_id)
    new_records = ApplicationGroup.import(
      missing_group_ids.map do |group_id|
        ApplicationGroup.new(application_id: application_id, group_id: group_id)
      end, on_duplicate_key_ignore: true
    ).results
    outputs.application_groups += new_records

    # Run the first query again in case another process or thread
    # inserted the missing records before us
    existing_group_ids = missing_group_ids - new_records.map(&:group_id)
    outputs.application_groups += ApplicationGroup.where(
      application_id: application_id, group_id: existing_group_ids
    ).to_a
  end
end
