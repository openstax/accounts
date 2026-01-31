class AddSalesforceBookIdToBooks < ActiveRecord::Migration[6.0]
  def change
    add_column :books, :salesforce_book_id, :string
    add_index :books, :salesforce_book_id, unique: true
  end
end
