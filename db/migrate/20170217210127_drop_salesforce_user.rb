class DropSalesforceUser < ActiveRecord::Migration[4.2]
  def up
    drop_table 'salesforce_users'
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
