class AddLastSeenToUsers < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_column :users, :last_seen_at, :datetime, if_not_exists: true
    add_column :users, :salesforce_student_last_seen_pushed_at, :datetime, if_not_exists: true
    add_column :users, :salesforce_contact_last_seen_pushed_at, :datetime, if_not_exists: true

    add_index :users, %i[salesforce_student_last_seen_pushed_at last_seen_at],
              where: '(role = 1) AND (salesforce_student_id IS NOT NULL)',
              name: 'index_users_linked_students_by_last_seen',
              algorithm: :concurrently, if_not_exists: true

    add_index :users, %i[salesforce_contact_last_seen_pushed_at last_seen_at],
              where: 'salesforce_contact_id IS NOT NULL',
              name: 'index_users_with_contact_by_last_seen',
              algorithm: :concurrently, if_not_exists: true
  end
end
