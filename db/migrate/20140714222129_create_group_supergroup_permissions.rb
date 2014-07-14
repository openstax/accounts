class CreateGroupSupergroupPermissions < ActiveRecord::Migration
  def change
    create_table :group_supergroup_permissions do |t|
      t.references :group_supergroup, null: false
      t.string :permission, null: false

      t.timestamps
    end

    add_index :group_supergroup_permissions, [:group_supergroup_id, :permission],
              name: 'index_gsp_on_gs_id_and_p', unique: true
  end
end
