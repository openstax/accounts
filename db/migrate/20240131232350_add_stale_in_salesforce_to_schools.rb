class AddStaleInSalesforceToSchools < ActiveRecord::Migration[5.2]
  def change
    add_column :schools, :stale_in_salesforce, :boolean
  end
end
