class SetDoorkeeperScopes < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    change_column_default :oauth_access_grants, :scopes, ''
    Doorkeeper::AccessGrant.in_batches.update_all scopes: 'all'
    change_column_null :oauth_access_grants, :scopes, false

    change_column_default :oauth_access_tokens, :scopes, ''
    Doorkeeper::AccessToken.in_batches.update_all scopes: 'all'
    change_column_null :oauth_access_tokens, :scopes, false
  end

  def down
    change_column_null :oauth_access_tokens, :scopes, true
    Doorkeeper::AccessToken.in_batches.update_all scopes: ''
    change_column_default :oauth_access_tokens, :scopes, nil

    change_column_null :oauth_access_grants, :scopes, true
    Doorkeeper::AccessGrant.in_batches.update_all scopes: ''
    change_column_default :oauth_access_grants, :scopes, nil
  end
end
