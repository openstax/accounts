class RemoveBanners < ActiveRecord::Migration[5.2]
  def up
    drop_table(:banners) if table_exists?(:banners)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
