class AddSalesforceStudentPushedAtToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :salesforce_student_pushed_at, :datetime

    add_index :users, :id,
              where: 'school_id IS NOT NULL AND salesforce_student_pushed_at IS NULL',
              name: 'index_users_unpushed_students_with_school'
  end
end
