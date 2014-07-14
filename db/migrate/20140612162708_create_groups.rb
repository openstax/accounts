class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string :name, null: false
      t.references :owner, polymorphic: true, null: false

      t.timestamps
    end

    add_index :groups, [:owner_id, :owner_type, :name], unique: true
    add_index :groups, :name
  end
end
