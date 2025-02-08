# Finds or creates an ApplicationUser for the given application and user.
class FindOrCreateApplicationUser
  lev_routine

  protected

  def exec(application_id, user_id)
    # Attempt to insert the record, ignoring conflicts
    # If no record is inserted, query the existing record
    outputs.application_user = ApplicationUser.import(
      [ ApplicationUser.new(application_id: application_id, user_id: user_id) ],
      on_duplicate_key_ignore: true
    ).results.first || ApplicationUser.find_by(application_id: application_id, user_id: user_id)
  end
end
