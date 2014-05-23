class CreateMessageRecipients < ActiveRecord::Migration
  def change
    create_table :message_recipients do |t|
      t.integer :message_id, null: false
      t.integer :contact_info_id
      t.integer :user_id
      t.string :type, null: false
      t.boolean :read, null: false, default: false

      t.timestamps
    end

    add_index :message_recipients, [:message_id, :user_id],
                                   unique: true
    add_index :message_recipients, [:contact_info_id, :message_id],
                                   unique: true
    add_index :message_recipients, [:user_id, :read]
  end
end
