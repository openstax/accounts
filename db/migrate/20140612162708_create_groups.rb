class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string :name
      t.boolean :is_public, null: false, default: false

      t.timestamps
    end

    add_index :groups, :name, unique: true
    add_index :groups, :is_public
  end
end
