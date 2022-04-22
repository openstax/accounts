class RemoveOldAccessTokens < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def up
    ActiveRecord::Base.transaction do
      Rake::Task['doorkeeper:cleanup'].invoke

      Doorkeeper::AccessToken.where(
        <<-SQL.squish.strip_heredoc
          EXISTS (
            SELECT *
              FROM "oauth_access_tokens" "oat"
              WHERE "oat"."resource_owner_id" = "oauth_access_tokens"."resource_owner_id"
                AND "oat"."application_id" = "oauth_access_tokens"."application_id"
                AND "oat"."created_at" > "oauth_access_tokens"."created_at"
          )
        SQL
      ).delete_all
    end

    Doorkeeper::AccessToken.connection.execute 'VACUUM FULL ANALYZE "oauth_access_grants"'
    Doorkeeper::AccessToken.connection.execute 'VACUUM FULL ANALYZE "oauth_access_tokens"'
  end

  def down
  end
end
