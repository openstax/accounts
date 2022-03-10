class AddSalesforceOxAccountId < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :salesforce_ox_account_id, :string
    add_index :users, :salesforce_ox_account_id
  end
end
