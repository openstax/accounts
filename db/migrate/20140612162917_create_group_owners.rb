class CreateGroupOwners < ActiveRecord::Migration
  def change
    create_table :group_owners do |t|
      t.references :group, null: false
      t.references :user, null: false

      t.timestamps
    end

    add_index :group_owners, [:group_id, :user_id], unique: true
    add_index :group_owners, :user_id
  end
end
