# frozen_string_literal: true

class ChangeOldUsersToNewState < ActiveRecord::Migration[5.2]
  def up
    User.where(state: 'needs_profile').each do |user|
      user.state = :unverified
      user.faculty_status = :incomplete_signup

      SecurityLog.create(
        event_type: :user_updated,
        user: user,
        event_data: {
          state_was: 'needs_profile',
          state_changed_to: 'unverified',
          faculty_status_changed_to: 'incomplete_signup'
        }
      )

    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
