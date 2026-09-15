class FixUnpushedStudentsIndexPredicate < ActiveRecord::Migration[6.1]
  def change
    remove_index :users, name: 'index_users_unpushed_students_with_school'

    # role = 1 is User::STUDENT_ROLE (integer-backed enum)
    add_index :users, :id,
              where: 'role = 1 AND school_id IS NOT NULL AND salesforce_student_pushed_at IS NULL',
              name: 'index_users_unpushed_students_with_school'
  end
end
