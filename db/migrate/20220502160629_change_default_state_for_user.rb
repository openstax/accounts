class ChangeDefaultStateForUser < ActiveRecord::Migration[5.2]
  def up
    change_column_default(:users, :state, :incomplete_signup)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
