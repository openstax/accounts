class CreateUserBooks < ActiveRecord::Migration[6.1]
  # if_not_exists: databases that ran this as version 20260915200002 already have it.
  def change
    create_table :user_books, if_not_exists: true do |t|
      t.references :user, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true

      t.timestamps
    end

    add_index :user_books, [:user_id, :book_id], unique: true, if_not_exists: true
  end
end
