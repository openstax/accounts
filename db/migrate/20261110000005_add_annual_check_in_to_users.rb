class AddAnnualCheckInToUsers < ActiveRecord::Migration[6.1]
  # if_not_exists: databases that ran this as version 20260915200005 already have it.
  def change
    add_column :users, :check_in_completed_at, :datetime, if_not_exists: true
    add_column :users, :check_in_dismissed_at, :datetime, if_not_exists: true
    add_column :users, :check_in_dismissal_count, :integer,
               default: 0, null: false, if_not_exists: true
  end
end
