class RemoveGroups < ActiveRecord::Migration[5.2]
  def up
    drop_table :groups
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
