class AddAccountDeletionTokenToUsers < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_column :users, :account_deletion_token, :string, if_not_exists: true
    add_column :users, :account_deletion_token_expires_at, :datetime, if_not_exists: true

    add_index :users, :account_deletion_token,
              unique: true,
              algorithm: :concurrently, if_not_exists: true
  end
end
