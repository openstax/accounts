class AddSalesforceBooks < ActiveRecord::Migration[5.2]
  def change
    create_table :books do |t|
      t.string :salesforce_id
      t.string :salesforce_name
      t.string :official_name
      t.timestamps
    end
  end
end
