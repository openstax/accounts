class AddSignupDoneCapturedAtToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :signup_done_captured_at, :datetime
  end
end
