class AddBooksUsedDetailsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :books_used_details, :jsonb
  end
end
