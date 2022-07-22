class RemovePushMigrations < ActiveRecord::Migration[5.2]
  def up
    drop_table :push_topics
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
