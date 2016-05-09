class CreateSecurityLogs < ActiveRecord::Migration
  def change
    create_table :security_logs do |t|
      t.references :user
      t.references :application
      t.string :remote_ip, null: false
      t.integer :event_type, null: false
      t.text :event_data, null: false, default: '{}'

      t.timestamps null: false
    end

    add_index :security_logs, [:user_id,        :created_at]
    add_index :security_logs, [:application_id, :created_at]
    add_index :security_logs, [:remote_ip,      :created_at]
    add_index :security_logs, [:created_at,     :event_type]
  end
end
