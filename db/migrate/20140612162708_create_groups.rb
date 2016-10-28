class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.boolean :is_public, null: false, default: false
      t.string :name
      t.text :cached_subtree_group_ids
      t.text :cached_supertree_group_ids

      t.timestamps null: false
    end

    add_index :groups, :is_public
  end
end
