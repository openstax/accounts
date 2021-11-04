class DropPreAuthStateTable < ActiveRecord::Migration[5.2]
  def up
    drop_table :pre_auth_states
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
