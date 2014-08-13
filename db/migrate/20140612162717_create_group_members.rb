class CreateGroupMembers < ActiveRecord::Migration
  def change
    create_table :group_members do |t|
      t.references :group, null: false
      t.references :user, null: false

      t.timestamps
    end

    add_index :group_members, [:group_id, :user_id], unique: true
    add_index :group_members, :user_id
  end
end
