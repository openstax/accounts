class RemoveGroupMembers < ActiveRecord::Migration[5.2]
  def up
    drop_table :group_members
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
