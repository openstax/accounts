class AddUserIdToIdentities < ActiveRecord::Migration
  def change
    add_column :identities, :user_id, :integer
    change_column :identities, :user_id, :integer, :null => false
    add_index :identities, :user_id
  end
end
