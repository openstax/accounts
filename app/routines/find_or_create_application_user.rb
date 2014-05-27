# Finds or creates an ApplicationUser for the given application and user.
class FindOrCreateApplicationUser

  lev_routine

protected

  def exec(application_id, user_id)
    application_user = ApplicationUser.where(:application_id => application_id,
                                             :user_id => user_id).first
    unless application_user
      application_user = ApplicationUser.create do |app_user|
        app_user.application_id = application_id
        app_user.user_id = user_id
        app_user.save!
      end
    end

    outputs[:application_user] = application_user
  end

end