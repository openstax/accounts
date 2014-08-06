class CreateGroupStaffs < ActiveRecord::Migration
  def change
    create_table :group_staffs do |t|
      t.references :group, null: false
      t.references :user, null: false
      t.string :role, null: false, default: 'viewer'

      t.timestamps
    end

    add_index :group_staffs, [:group_id, :user_id, :role], unique: true
    add_index :group_staffs, :user_id
  end
end
