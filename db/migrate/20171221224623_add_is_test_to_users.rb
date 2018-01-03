class AddIsTestToUsers < ActiveRecord::Migration
  def change
    add_column :users, :is_test, :boolean
  end
end
