class RemoveNeedsSync < ActiveRecord::Migration[5.2]
  def up
    remove_column(:users, :needs_sync)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
