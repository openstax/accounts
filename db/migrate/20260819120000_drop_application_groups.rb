class DropApplicationGroups < ActiveRecord::Migration[6.1]
  def up
    drop_table :application_groups
  end

  def down
    create_table :application_groups do |t|
      t.integer :application_id, null: false
      t.integer :group_id, null: false
      t.integer :unread_updates, null: false, default: 1
      t.timestamps
    end
    add_index :application_groups, [:group_id, :application_id], unique: true
    add_index :application_groups, [:group_id, :unread_updates]
    add_index :application_groups, [:application_id, :unread_updates]
  end
end
