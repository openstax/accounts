class AddSalesforceForgottenAtToUsers < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  # The nightly ForgetDeletedUsersInSalesforce pass selects deleted users still
  # linked to a Contact or Lead that haven't been flagged yet; without this the
  # predicate scans every user.
  def change
    add_column :users, :salesforce_forgotten_at, :datetime, if_not_exists: true

    add_index :users, :id,
              where: 'is_deleted = true AND salesforce_forgotten_at IS NULL AND ' \
                     '(salesforce_contact_id IS NOT NULL OR salesforce_lead_id IS NOT NULL)',
              name: 'index_users_deleted_pending_salesforce_forget',
              algorithm: :concurrently, if_not_exists: true
  end
end
