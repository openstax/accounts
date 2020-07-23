class AddIsSheeridUnviableToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :is_sheerid_unviable, :boolean
  end
end
