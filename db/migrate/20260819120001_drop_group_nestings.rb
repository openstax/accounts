class DropGroupNestings < ActiveRecord::Migration[6.1]
  def up
    drop_table :group_nestings
  end

  def down
    create_table :group_nestings do |t|
      t.integer :member_group_id, null: false
      t.integer :container_group_id, null: false
      t.timestamps
    end
    add_index :group_nestings, :member_group_id, unique: true
    add_index :group_nestings, :container_group_id
  end
end
