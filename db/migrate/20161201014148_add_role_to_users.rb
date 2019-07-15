class AddRoleToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :role, :integer, default: 0, null: false
    add_index :users, :role
  end
end
