class CreateGroupSupergroups < ActiveRecord::Migration
  def change
    create_table :group_supergroups do |t|
      t.references :group, null: false
      t.references :supergroup, null: false

      t.timestamps
    end

    add_index :group_supergroups, [:group_id, :supergroup_id], unique: true
    add_index :group_supergroups, :supergroup_id
  end
end
