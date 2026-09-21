class AddLoginTrackingAndSalesforceStudentIdToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :last_signed_in_at, :datetime
    add_column :users, :salesforce_student_id, :string

    add_index :users, :salesforce_student_id,
              name: 'index_users_on_salesforce_student_id'

    # The one-shot predicate only ever described students awaiting their first
    # push; the sync now also revisits linked students whose login moved on.
    remove_index :users, name: 'index_users_unpushed_students_with_school'

    # role = 1 is User::STUDENT_ROLE (integer-backed enum)
    add_index :users, :id,
              where: 'role = 1 AND school_id IS NOT NULL AND salesforce_student_pushed_at IS NULL',
              name: 'index_users_unlinked_students_with_school'

    add_index :users, %i[salesforce_student_pushed_at last_signed_in_at],
              where: 'role = 1 AND salesforce_student_id IS NOT NULL',
              name: 'index_users_linked_students_by_login'
  end
end
