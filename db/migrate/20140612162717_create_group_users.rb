class CreateGroupUsers < ActiveRecord::Migration
  def change
    create_table :group_users do |t|
      t.references :group, null: false
      t.references :user, null: false
      t.integer :access_level, null: false, default: 0

      t.timestamps
    end

    add_index :group_users, [:user_id, :group_id], unique: true
    add_index :group_users, :group_id
  end
end
