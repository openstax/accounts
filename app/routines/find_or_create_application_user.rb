# Finds or creates an ApplicationUser for the given application and user.
class FindOrCreateApplicationUser

  lev_routine

protected

  def exec(application, user)
    app_user = application.application_users.where(:user_id => user.id).first
    return app_user if app_user

    app_user = ApplicationUser.new
    app_user.application = application
    app_user.user = user
    app_user.save!
    app_user
  end

end