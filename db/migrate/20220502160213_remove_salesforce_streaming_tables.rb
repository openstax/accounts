class RemoveSalesforceStreamingTables < ActiveRecord::Migration[5.2]
  def up
    drop_table(:salesforce_streaming_replays) if table_exists?(:salesforce_streaming_replays)
    drop_table(:push_topics) if table_exists?(:push_topics)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
