class AddIndexUsersStudentsMissingSignupPush < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  # Serves the nightly signup-date pass: linked students not yet sent, newest first.
  def change
    add_index :users, :id,
              where: 'role = 1 AND salesforce_student_id IS NOT NULL AND salesforce_student_signup_pushed_at IS NULL',
              name: 'index_users_linked_students_missing_signup_push',
              algorithm: :concurrently, if_not_exists: true
  end
end
