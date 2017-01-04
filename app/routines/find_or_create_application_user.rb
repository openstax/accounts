# Finds or creates an ApplicationUser for the given application and user.
class FindOrCreateApplicationUser

  lev_routine

  protected

  def exec(application_id, user_id)
    application_user = ApplicationUser.find_or_create_by(application_id: application_id,
                                                         user_id: user_id)

    outputs[:application_user] = application_user
  end

end
