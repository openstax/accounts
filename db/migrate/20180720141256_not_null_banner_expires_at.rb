class NotNullBannerExpiresAt < ActiveRecord::Migration
  def change
    change_column_null :banners, :expires_at, false
  end
end
