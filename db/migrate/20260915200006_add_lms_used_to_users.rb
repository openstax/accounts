class AddLmsUsedToUsers < ActiveRecord::Migration[6.1]
  def change
    # Self-reported answer to the Overview "do you use an LMS?" card. Stores
    # one of User::LMS_OPTIONS' keys (e.g. "canvas", "none"); nil means unanswered.
    add_column :users, :lms_used, :string
    add_column :users, :lms_prompt_dismissed_at, :datetime
  end
end
