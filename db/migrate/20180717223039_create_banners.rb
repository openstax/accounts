class CreateBanners < ActiveRecord::Migration
  def change
    create_table :banners do |t|
      t.string :message, null: false
      t.datetime :expires_at

      t.timestamps null: false
    end
  end
end
