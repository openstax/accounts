class AddPendingCsVerificationToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :is_educator_pending_cs_verification, :boolean
  end
end
