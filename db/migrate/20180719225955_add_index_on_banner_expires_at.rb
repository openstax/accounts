class AddIndexOnBannerExpiresAt < ActiveRecord::Migration
  def change
    add_index :banners, :expires_at
  end
end
