class RemoveGroupNestings < ActiveRecord::Migration[5.2]
  def up
    drop_table :group_nestings if table_exists?(:group_nestings)
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
