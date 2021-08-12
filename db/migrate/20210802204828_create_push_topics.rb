class CreatePushTopics < ActiveRecord::Migration[5.2]
  def change
    create_table :push_topics do |t|
      t.string :topic_salesforce_id
      t.string :topic_name
    end
  end
end
