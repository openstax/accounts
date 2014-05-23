class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.integer :application_id, null: false
      t.integer :sender_id
      t.boolean :send_externally_now, null: false, default: false
      t.text :subject, null: false
      t.string :subject_prefix, null: false, default: ''

      t.timestamps
    end

    add_index :messages, [:application_id, :sender_id]
    add_index :messages, :sender_id
  end
end
