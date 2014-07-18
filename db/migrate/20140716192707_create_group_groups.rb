class CreateGroupGroups < ActiveRecord::Migration
  def change
    create_table :group_groups do |t|
      t.references :permitter_group, null: false
      t.references :permitted_group, null: false
      t.string :role, null: false

      t.timestamps
    end

    add_index :group_groups, [:permitted_group_id, :permitter_group_id, :role],
                             name: 'index_group_groups_on_pg_id_and_pg_id_and_r',
                             unique: true
    add_index :group_groups, [:permitter_group_id, :role]
  end
end
