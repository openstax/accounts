# Routine for listing users that use a certain app
# 
# Caller provides the Doorkeeper::Application and the last_updated_at param

class ApplicationUsersUpdatedAfter

  # This transaction needs :repeatable_read to prevent missed updates
  # in case 2 users update at the same time as this API is called
  # Actually, ActiveRecord must be the one using :repeatable_read
  # (true by default for MySQL, false by default for PostgreSQL)
  # As long as ActiveRecord is using :repeatable_read, we can probably
  # reduce this transaction's isolation level to :read_committed
  lev_routine transaction: :repeatable_read

protected

  def exec(application, time = nil)
    return if application.nil?
    app_users = application.application_users
    if time
      users = User.arel_table
      app_users = app_users.joins(:user).where(
                    users[:updated_at].gteq(Time.at(time.to_i))
                  )
    end
    outputs[:application_users] = app_users
  end

end