class AddSalesforceStudentPushedAtToUsers < ActiveRecord::Migration[6.1]
  # Concurrent index builds cannot run inside a transaction, so nothing here is
  # rolled back on failure -- every statement is written to be re-runnable.
  disable_ddl_transaction!

  def change
    add_column :users, :salesforce_student_pushed_at, :datetime, if_not_exists: true

    # The index this migration used to build was replaced twice before landing
    # on index_users_unlinked_students_with_school in 20260915060000. Building
    # it here only to drop it there costs two extra full scans of users on any
    # database migrating from scratch.
  end
end
