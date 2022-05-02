# frozen_string_literal: true

class ChangeNeedsProfileInstructorsToIncompleteSignup < ActiveRecord::Migration[5.2]
  def up
    User
      .where(state: :needs_profile, faculty_status: :confirmed_faculty)
      .update_all( # rubocop:disable Rails/SkipsModelValidations
        state: :activated, faculty_status: :incomplete_signup
      )
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
