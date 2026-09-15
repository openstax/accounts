class AddAnnualCheckInToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :check_in_completed_at, :datetime
    add_column :users, :check_in_dismissed_at, :datetime
    add_column :users, :check_in_dismissal_count, :integer, default: 0, null: false
  end
end
