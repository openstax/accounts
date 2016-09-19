class AddSalesforceInfoToUsers < ActiveRecord::Migration
  def change
    add_column :users, :salesforce_contact_id, :string
    add_column :users, :faculty_status, :integer, default: 0, null: false

    add_index :users, :faculty_status
    add_index :users, :salesforce_contact_id
  end
end
