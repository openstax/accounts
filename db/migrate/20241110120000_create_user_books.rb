class CreateUserBooks < ActiveRecord::Migration[6.1]
  def change
    create_table :user_books do |t|
      t.references :user, null: false, foreign_key: true
      t.string :book_uuid, null: false
      t.string :title, null: false
      t.string :cover_url
      t.string :salesforce_name

      t.timestamps
    end

    add_index :user_books, [:user_id, :book_uuid], unique: true
  end
end
