class AddIsSheeridVerifiedToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :is_sheerid_verified, :boolean
  end
end
