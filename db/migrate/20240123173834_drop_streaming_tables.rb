class DropStreamingTables < ActiveRecord::Migration[5.2]
  def up
    drop_table :salesforce_streaming_replays
    drop_table :push_topics
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
