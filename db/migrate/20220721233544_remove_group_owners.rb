class RemoveGroupOwners < ActiveRecord::Migration[5.2]
  def up
    drop_table :group_owners
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
