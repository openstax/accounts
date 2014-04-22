# Routine for listing users that use a certain app
# 
# Caller provides the Doorkeeper::Application and the last_updated_at param

class ListUsers

  lev_routine transaction: :no_transaction

protected

  def exec(application, last_updated_at = nil)
    app_users = application.users
    if last_updated_at
      users = User.arel_table
      # As far as I know, timestamps are calculated in Rails, not in the DB.
      # This makes the following scenario possible:
      #
      # 2 users update their info at the same time as an app requests it
      # (3 processes)
      #
      # Assume rails calculates the updated_at timestamps in this order:
      # Process 1: User #1 updated_at = some_unix_second + 0.99999 second
      # ... the next second ticks ...
      # Process 2: User #2 updated_at = some_unix_second + 1.00001 second
      #
      # Consider the DB accesses happen in this order:
      # Process 2: User #2 update
      # Process 3: Read for app's API call
      # Process 1: User #1 update
      #
      # App will receive user #2's updated_at value and skip user #1's forever
      #
      # To try to mitigate this, I'm giving this API call a 2 second slack.
      # (one second is subtracted, the other is in the gteq operator)
      # Not a perfect solution, but I got nothing else short of locking the whole
      # table while timestamps are calculated (which is very bad).
      #
      # Hopefully it will never take more than a full second between calculating
      # a timestamp and writing it to the DB.
      # If it does, we probably have other, more important problems.
      #
      # This also means there will always be at least 1 user in the response to
      # this API call under normal operation (the last user to update their info)
      #
      # Now, the above scenario could also happen at the same time that a leap
      # second occurs, but I really don't feel like trying to reason about that.
      # :) Probably more likely to have a meteor hit the datacenter.
      #
      last_updated_time = Time.at(last_updated_at.to_i) - 1.second
      app_users = app_users.where(users[:updated_at].gteq(last_updated_time))
    end
    outputs[:users] = app_users
  end

end