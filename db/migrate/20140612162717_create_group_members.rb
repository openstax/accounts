class CreateGroupMembers < ActiveRecord::Migration[4.2]
  def change
    create_table :group_members do |t|
      t.references :group, null: false
      t.references :user, null: false

      t.timestamps null: false
    end

    add_index :group_members, [:group_id, :user_id], unique: true
    add_index :group_members, :user_id
  end
end
