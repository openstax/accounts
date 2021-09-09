class CreateSalesforceStreamingReplays < ActiveRecord::Migration[5.2]
  def change
    create_table :salesforce_streaming_replays do |t|
      t.references :push_topics, foreign_key: true
      t.timestamps
    end
  end
end
