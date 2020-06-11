class AddSheeridVerificationIdToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :sheerid_verification_id, :string
  end
end
