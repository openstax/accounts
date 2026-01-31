class AddAssignableBookToUserBooks < ActiveRecord::Migration[6.1]
  def change
    add_column :user_books, :assignable_book, :boolean, default: false, null: false
  end
end
