class RemoveOwnerFromTokens < ActiveRecord::Migration[5.2]
  def change
    remove_column :oauth_access_tokens, :resource_owner_id
  end
end
