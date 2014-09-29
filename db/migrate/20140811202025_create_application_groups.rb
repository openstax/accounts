class CreateApplicationGroups < ActiveRecord::Migration
  def change
    create_table :application_groups do |t|
      t.references :application, null: false
      t.references :group, null: false
      t.integer :unread_updates, null: false, default: 1

      t.timestamps
    end

    add_index :application_groups, [:group_id, :application_id], unique: true
    add_index :application_groups, [:group_id, :unread_updates]
    add_index :application_groups, [:application_id, :unread_updates]
  end
end
