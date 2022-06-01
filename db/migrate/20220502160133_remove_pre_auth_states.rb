class RemovePreAuthStates < ActiveRecord::Migration[5.2]
  def up
    drop_table(:pre_auth_states) if table_exists?(:pre_auth_states)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
