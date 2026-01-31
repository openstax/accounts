class AddSalesforceBookIdToAdoptions < ActiveRecord::Migration[6.0]
  def change
    add_column :adoptions, :salesforce_book_id, :string
    add_index :adoptions, :salesforce_book_id
  end
end
