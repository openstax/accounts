class AddReplayIdToSalesforceStreamingReplays < ActiveRecord::Migration[5.2]
  def change
    add_column :salesforce_streaming_replays, :replay_id, :integer
  end
end
