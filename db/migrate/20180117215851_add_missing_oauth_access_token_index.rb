class AddMissingOauthAccessTokenIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :oauth_access_tokens, [ :application_id, :created_at ],
              where: '"resource_owner_id" IS NULL AND "revoked_at" IS NULL'
  end
end
