class RemoveMessagingTables < ActiveRecord::Migration[5.2]
  def up
    drop_table :messages if table_exists?(:messages)
    drop_table :message_bodies if table_exists?(:message_bodies)
    drop_table :message_recipients if table_exists?(:message_recipients)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
