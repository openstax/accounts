class RemoveFacultyVerificationEmailSent < ActiveRecord::Migration[5.2]
  def change
    remove_column(:users, :faculty_verification_email_sent)
  end
end
