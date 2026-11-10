class AddLmsUsedToUsers < ActiveRecord::Migration[6.1]
  # if_not_exists: databases that ran this as version 20260915200006 already have it.
  def change
    # Self-reported answer to the Overview "do you use an LMS?" card. Stores
    # one of User::LMS_OPTIONS' keys (e.g. "canvas", "none"); nil means unanswered.
    add_column :users, :lms_used, :string, if_not_exists: true
    add_column :users, :lms_prompt_dismissed_at, :datetime, if_not_exists: true
  end
end
