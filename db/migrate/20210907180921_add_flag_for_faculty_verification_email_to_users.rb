class AddFlagForFacultyVerificationEmailToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :faculty_verification_email_sent, :boolean
  end
end
