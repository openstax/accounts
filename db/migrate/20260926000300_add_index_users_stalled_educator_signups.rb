class AddIndexUsersStalledEducatorSignups < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  # The nightly SyncEducatorLeads pass selects activated educators with no Lead
  # and no Contact; without this the predicate scans every user.
  def change
    add_index :users, :created_at,
              where: "salesforce_lead_id IS NULL AND salesforce_contact_id IS NULL AND role <> 1 AND state = 'activated'",
              name: 'index_users_stalled_educator_signups',
              algorithm: :concurrently, if_not_exists: true
  end
end
