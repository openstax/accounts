class AddUserIdToIdentities < ActiveRecord::Migration[4.2]
  def change
    add_column :identities, :user_id, :integer
    change_column :identities, :user_id, :integer, null: false
    add_index :identities, :user_id
  end
end
