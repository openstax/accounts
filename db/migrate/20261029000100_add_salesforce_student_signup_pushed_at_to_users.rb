class AddSalesforceStudentSignupPushedAtToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :salesforce_student_signup_pushed_at, :datetime, if_not_exists: true
  end
end
