class AddIndexOnBannerExpiresAt < ActiveRecord::Migration[4.2]
  def change
    add_index :banners, :expires_at
  end
end
