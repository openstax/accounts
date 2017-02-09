class DropSalesforceUser < ActiveRecord::Migration
  def up
    drop_table 'salesforce_users'
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
