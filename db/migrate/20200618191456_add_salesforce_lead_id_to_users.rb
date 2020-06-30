class AddSalesforceLeadIdToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :salesforce_lead_id, :string, after: :salesforce_contact_id
  end
end
