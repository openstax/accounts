class DropSettings < ActiveRecord::Migration[5.2]
  def change
    drop_table(:settings) if table_exists?(:settings)
  end
end
