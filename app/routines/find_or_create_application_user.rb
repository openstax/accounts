# Finds or creates an ApplicationUser for the given application and user.
class FindOrCreateApplicationUser

  lev_routine

protected

  def exec(application_id, user_id)
    app_user = ApplicationUser.where(:application_id => application_id,
                                     :user_id => user_id).first
    return app_user if app_user

    app_user = ApplicationUser.new
    app_user.application_id = application_id
    app_user.user_id = user_id
    app_user.save!
    app_user
  end

end