class RemoveFacultyVerificationEmailSent < ActiveRecord::Migration[5.2]
  def up
    remove_column(:users, :faculty_verification_email_sent)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
