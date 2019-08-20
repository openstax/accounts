class AddIsTestToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :is_test, :boolean
  end
end
