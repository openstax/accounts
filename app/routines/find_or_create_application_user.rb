# Finds or creates an ApplicationUser for the given application and user.
class FindOrCreateApplicationUser
  lev_routine transaction: :read_committed

  protected

  def exec(application_id, user_id)
    # First attempt to query the record
    # If no record found, attempt to insert it record, ignoring conflicts
    # If no record is inserted, query the existing record again
    # The first query is necessary to prevent the id sequence from autoincrementing
    # every time this routine is called
    # We can remove it if we switch the primary key to a uuid column
    outputs.application_user = ApplicationUser.find_by(
      application_id: application_id, user_id: user_id
    ) || ApplicationUser.import(
      [ ApplicationUser.new(application_id: application_id, user_id: user_id) ],
      on_duplicate_key_ignore: true
    ).results.first || ApplicationUser.find_by(
      application_id: application_id, user_id: user_id
    )
  end
end
