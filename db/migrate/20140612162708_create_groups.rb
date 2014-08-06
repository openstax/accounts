class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.boolean :is_public, null: false, default: false
      t.string :name
      t.text :cached_container_group_ids
      t.text :cached_member_group_ids

      t.timestamps
    end

    add_index :groups, :is_public
  end
end
