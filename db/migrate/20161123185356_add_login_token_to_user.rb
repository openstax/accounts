class AddLoginTokenToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :login_token, :string
    add_column :users, :login_token_expires_at, :datetime

    add_index :users, :login_token, unique: true
  end
end
