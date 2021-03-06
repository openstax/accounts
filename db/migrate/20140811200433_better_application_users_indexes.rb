class BetterApplicationUsersIndexes < ActiveRecord::Migration[4.2]
  def change
    remove_index :application_users, column: [:unread_updates]

    add_index :application_users, [:user_id, :unread_updates]
    add_index :application_users, [:application_id, :unread_updates]
  end
end
