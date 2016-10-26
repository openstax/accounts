class CreateMessageBodies < ActiveRecord::Migration
  def change
    create_table :message_bodies do |t|
      t.integer :message_id, null: false
      t.text :html, null: false, default: ''
      t.text :text, null: false, default: ''
      t.string :short_text, null: false, default: ''

      t.timestamps null: false
    end

    add_index :message_bodies, :message_id, unique: true
  end
end
