class AddProfileNudgeAndCompletionToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :profile_nudge_redirected_at, :datetime, if_not_exists: true
    add_column :users, :profile_completed_at, :datetime, if_not_exists: true
  end
end
