namespace :accounts do
  desc "Backfill users.last_seen_at from last_signed_in_at, so the first sync isn't all-NULL"
  # rake accounts:backfill_last_seen_at
  task backfill_last_seen_at: :environment do
    sql = <<~SQL
      UPDATE users
      SET last_seen_at = last_signed_in_at
      WHERE last_seen_at IS NULL
        AND last_signed_in_at IS NOT NULL
    SQL

    updated_count = ActiveRecord::Base.connection.update(sql)
    puts "Backfilled last_seen_at for #{updated_count} user(s)."
  end
end
