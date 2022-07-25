class RemoveApplicationGroups < ActiveRecord::Migration[5.2]
  def up
    drop_table :application_groups if table_exists?(:application_groups)
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
