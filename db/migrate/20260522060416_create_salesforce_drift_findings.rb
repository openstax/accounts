class CreateSalesforceDriftFindings < ActiveRecord::Migration[6.1]
  def change
    create_table :salesforce_drift_findings do |t|
      t.references :user, foreign_key: true, null: true
      t.string :category, null: false
      t.string :salesforce_record_type
      t.string :salesforce_record_id
      t.jsonb  :details, default: {}, null: false
      t.datetime :first_seen_at, null: false
      t.datetime :last_seen_at, null: false
      t.datetime :resolved_at
      t.timestamps

      t.index [:category, :resolved_at]
      t.index [:user_id, :category]
      t.index :last_seen_at
    end
  end
end
