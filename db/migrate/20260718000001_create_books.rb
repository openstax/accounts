class CreateBooks < ActiveRecord::Migration[6.1]
  def change
    create_table :books do |t|
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

    add_index :books, :book_uuid, unique: true
    add_index :books, :salesforce_book_id, unique: true
  end
end
