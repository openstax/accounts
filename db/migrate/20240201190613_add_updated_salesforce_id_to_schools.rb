class AddUpdatedSalesforceIdToSchools < ActiveRecord::Migration[5.2]
  def change
    add_column :schools, :updated_salesforce_id, :text
  end
end
