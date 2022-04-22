# https://github.com/doorkeeper-gem/doorkeeper/issues/500#issuecomment-257043085
# We never expire AccessTokens, but this task is still useful
# to clear old AccessGrants since those expire after 10 minutes
namespace :doorkeeper do
  desc 'Delete expired and revoked OAuth grants and tokens (default: >= 30 days ago).'
  task cleanup: :environment do
    expired_sql = <<-SQL.squish.strip_heredoc
      "revoked_at\" <= :delete_before
        OR "expires_in" * INTERVAL '1 second' + "created_at" <= :delete_before
    SQL
    expired_query = [
      expired_sql,
      delete_before: ENV.fetch('DOORKEEPER_CLEANUP_AFTER', 30 * 24 * 60 * 60).to_i.seconds.ago
    ]

    Doorkeeper::AccessGrant.where(expired_query).delete_all
    Doorkeeper::AccessToken.where(expired_query).delete_all
  end
end
