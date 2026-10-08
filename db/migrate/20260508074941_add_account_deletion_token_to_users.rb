class AddAccountDeletionTokenToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :account_deletion_token, :string
    add_column :users, :account_deletion_token_expires_at, :datetime

    add_index :users, :account_deletion_token, unique: true
  end
end
