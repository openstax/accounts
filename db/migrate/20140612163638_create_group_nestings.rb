class CreateGroupNestings < ActiveRecord::Migration
  def change
    create_table :group_nestings do |t|
      t.references :member_group, null: false
      t.references :container_group, null: false

      t.timestamps null: false
    end

    add_index :group_nestings, :member_group_id, unique: true
    add_index :group_nestings, :container_group_id
  end
end
