class AddIndexToUsersSalesforceLeadId < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :users, :salesforce_lead_id, algorithm: :concurrently, if_not_exists: true
  end
end
