class CreateBooks < ActiveRecord::Migration[6.1]
  # if_not_exists: databases that ran this as version 20260915200001 already have it.
  def change
    create_table :books, if_not_exists: true do |t|
      t.string :book_uuid, null: false
      t.string :title, null: false
      t.string :cover_url
      t.string :salesforce_name
      t.boolean :assignable_book, default: false, null: false
      t.string :webview_rex_link
      t.string :html_url
      t.string :salesforce_book_id

      t.timestamps
    end

    add_index :books, :book_uuid, unique: true, if_not_exists: true
    add_index :books, :salesforce_book_id, unique: true, if_not_exists: true
  end
end
