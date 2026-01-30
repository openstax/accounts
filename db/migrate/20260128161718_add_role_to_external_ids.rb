class AddRoleToExternalIds < ActiveRecord::Migration[6.1]
  def change
    add_column :external_ids, :role, :integer, null: false, default: 0

    add_index :external_ids, [:external_id, :role], unique: true

    remove_index :external_ids, :external_id
  end
end
