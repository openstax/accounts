class ExcludeSelfLearnersFromUsersStalledEducatorSignups < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  # SyncEducatorLeads skips self_learner (role 10); the predicate must stay
  # implied by that query or Postgres falls back to scanning users.
  def up
    remove_index :users, name: 'index_users_stalled_educator_signups', algorithm: :concurrently, if_exists: true
    add_index :users, :created_at,
              where: "salesforce_lead_id IS NULL AND salesforce_contact_id IS NULL AND role <> 1 AND role <> 10 AND state = 'activated'",
              name: 'index_users_stalled_educator_signups',
              algorithm: :concurrently, if_not_exists: true
  end

  def down
    remove_index :users, name: 'index_users_stalled_educator_signups', algorithm: :concurrently, if_exists: true
    add_index :users, :created_at,
              where: "salesforce_lead_id IS NULL AND salesforce_contact_id IS NULL AND role <> 1 AND state = 'activated'",
              name: 'index_users_stalled_educator_signups',
              algorithm: :concurrently, if_not_exists: true
  end
end
