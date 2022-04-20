# frozen_string_literal: true

class ChangeNeedsProfileInstructorsToIncompleteSignup < ActiveRecord::Migration[5.2]
  def up
    User.where(state: :needs_profile, faculty_status: :faculty_confirmed).update_all(
      state: :activated, faculty_verified: :incomplete_signup
    )
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
