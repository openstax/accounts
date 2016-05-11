class CreateSecurityLogs < ActiveRecord::Migration
  def change
    create_table :security_logs do |t|
      t.references :user
      t.references :application
      t.string :remote_ip, null: false
      t.integer :event_type, null: false
      t.text :event_data, null: false, default: '{}'

      t.datetime :created_at, null: false, index: true
    end

    add_index :security_logs, [:user_id,        :created_at]
    add_index :security_logs, [:application_id, :created_at]
    add_index :security_logs, [:remote_ip,      :created_at]
    add_index :security_logs, [:event_type,     :created_at]
  end
end
