class AddUnreadUpdatesToApplicationUsers < ActiveRecord::Migration[4.2]
  def change
    # default: 1 - To be safe and send this user on the next update
    #              after a new application user is created
    add_column :application_users, :unread_updates, :integer, null: false, default: 1

    add_index :application_users, :unread_updates
  end
end
