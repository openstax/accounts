class NotNullBannerExpiresAt < ActiveRecord::Migration[4.2]
  def change
    change_column_null :banners, :expires_at, false
  end
end
