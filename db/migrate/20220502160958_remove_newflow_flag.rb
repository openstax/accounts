class RemoveNewflowFlag < ActiveRecord::Migration[5.2]
  def up
    remove_column(:users, :is_newflow)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
