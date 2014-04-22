# Routine for listing users that use a certain app
# 
# Caller provides the Doorkeeper::Application and the last_updated_at param

class ListUsers

  lev_routine transaction: :no_transaction

protected

  def exec(application, last_updated_at = nil)
    users = User.arel_table
    app_users = application.users
    app_users = app_users.where(users[:updated_at].gteq(last_updated_at)) \
      if last_updated_at
    app_users
  end

end