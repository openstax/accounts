class RemoveOauthAccessTokenSizeLimit < ActiveRecord::Migration[5.2]
  def change
    change_column :oauth_access_tokens, :token, :text
  end
end
