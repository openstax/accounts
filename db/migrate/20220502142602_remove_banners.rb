class RemoveBanners < ActiveRecord::Migration[5.2]
  def change
    drop_table(:banners) if table_exists?(:banners)
  end
end
