class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.integer :application_id, null: false
      t.integer :user_id
      t.boolean :send_externally_now, null: false, default: false
      t.text :subject, null: false
      t.string :subject_prefix, null: false, default: ''

      t.timestamps null: false
    end

    add_index :messages, [:application_id, :user_id]
    add_index :messages, :user_id
  end
end
