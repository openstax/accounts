namespace :accounts do
  desc "Backfill users.last_signed_in_at from each user's most recent sign_in_successful security log"
  # rake accounts:backfill_last_signed_in_at
  task backfill_last_signed_in_at: :environment do
    sign_in_successful = SecurityLog.event_types.fetch('sign_in_successful')

    sql = <<~SQL
      UPDATE users
      SET last_signed_in_at = last_logins.last_signed_in_at
      FROM (
        SELECT user_id, MAX(created_at) AS last_signed_in_at
        FROM security_logs
        WHERE event_type = #{sign_in_successful} AND user_id IS NOT NULL
        GROUP BY user_id
      ) AS last_logins
      WHERE users.id = last_logins.user_id
        AND users.last_signed_in_at IS NULL
    SQL

    updated_count = ActiveRecord::Base.connection.update(sql)
    puts "Backfilled last_signed_in_at for #{updated_count} user(s)."
  end
end
