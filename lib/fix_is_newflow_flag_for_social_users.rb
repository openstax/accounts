# When we released the new student flow, users who signed up using a social (OAuth) provider
# like Facebook and Google did not get the `is_newflow` column set to true—unlike users who
# signed up with a password. So this class updates just those users who missed the flag.
class FixIsNewflowFlagForSocialUsers
  class << self
    def call
      ActiveRecord::Base.transaction do
        begin
          num_updated = users_missed.update_all(is_newflow: true)
          Rails.logger.info { "Updated #{num_updated} user(s)" }
        rescue Exception => e
          puts e
          Sentry.capture_exception(e)
          raise ActiveRecord::Rollback
        end
      end
    end

    private

    def users_missed
      User.where(
        <<~SQL
        id IN (
          SELECT u.id
          FROM users u
          JOIN authentications a1
          ON a1.user_id = u.id
          WHERE a1.id IN (
            SELECT min(a.id)
            FROM authentications a
            GROUP BY user_id
          )
          AND
          provider ~ 'newflow'
        )
        SQL
      )
    end
  end
end
