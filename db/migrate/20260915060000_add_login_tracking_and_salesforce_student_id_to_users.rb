class AddLoginTrackingAndSalesforceStudentIdToUsers < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_column :users, :last_signed_in_at, :datetime, if_not_exists: true
    add_column :users, :salesforce_student_id, :string, if_not_exists: true

    add_index :users, :salesforce_student_id,
              name: 'index_users_on_salesforce_student_id',
              algorithm: :concurrently, if_not_exists: true

    # Only present on databases that ran this migration's earlier form.
    remove_index :users, name: 'index_users_unpushed_students_with_school',
                 algorithm: :concurrently, if_exists: true

    # role = 1 is User::STUDENT_ROLE (integer-backed enum)
    add_index :users, :id,
              where: 'role = 1 AND school_id IS NOT NULL AND salesforce_student_pushed_at IS NULL',
              name: 'index_users_unlinked_students_with_school',
              algorithm: :concurrently, if_not_exists: true

    add_index :users, %i[salesforce_student_pushed_at last_signed_in_at],
              where: 'role = 1 AND salesforce_student_id IS NOT NULL',
              name: 'index_users_linked_students_by_login',
              algorithm: :concurrently, if_not_exists: true
  end
end
