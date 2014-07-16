class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string :name
      t.string :visibility, null: false, default: 'private'
      t.references :owner

      t.timestamps
    end

    add_index :groups, :name, unique: true
    add_index :groups, :visibility
    add_index :groups, :owner_id
  end
end
