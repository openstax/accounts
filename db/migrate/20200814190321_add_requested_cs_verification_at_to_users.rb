class AddRequestedCsVerificationAtToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :requested_cs_verification_at, :datetime
  end
end
