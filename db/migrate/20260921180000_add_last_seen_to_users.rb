class AddLastSeenToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :last_seen_at, :datetime
    add_column :users, :salesforce_last_seen_pushed_at, :datetime

    add_index :users, %i[salesforce_last_seen_pushed_at last_seen_at],
              where: 'salesforce_contact_id IS NOT NULL',
              name: 'index_users_with_contact_by_last_seen'

    add_index :users, %i[salesforce_last_seen_pushed_at last_seen_at],
              where: '(role = 1) AND (salesforce_student_id IS NOT NULL)',
              name: 'index_users_linked_students_by_last_seen'
  end
end
