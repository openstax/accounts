class CreateEmailDeliveries < ActiveRecord::Migration[6.1]
  def change
    create_table :email_deliveries do |t|
      t.references :contact_info, type: :integer, foreign_key: { on_delete: :cascade }, null: false
      t.string :kind, null: false
      t.string :recipient, null: false
      t.integer :status, null: false, default: 0
      t.text :status_detail
      t.string :ses_message_id
      t.integer :send_attempts, null: false, default: 0
      t.datetime :sent_at
      t.datetime :delivered_at
      t.datetime :status_changed_at
      t.jsonb :last_event
      t.timestamps
    end

    add_index :email_deliveries, :ses_message_id
    add_index :email_deliveries, [:kind, :created_at]
  end
end
