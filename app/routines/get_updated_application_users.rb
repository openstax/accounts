# Routine for listing users that use a certain app
# 
# Caller provides the Doorkeeper::Application

class GetUpdatedApplicationUsers

  # This transaction needs :repeatable_read to prevent missed updates
  # in case 2 users update at the same time as this API is called
  # Actually, ActiveRecord must be the one using :repeatable_read
  # (true by default for MySQL, false by default for PostgreSQL)
  lev_routine transaction: :repeatable_read

protected

  def exec(application)
    return if application.nil?
    outputs[:application_users] = application.application_users.where{unread_updates > 0}
  end

end
