class AddIsTempToUsers < ActiveRecord::Migration
  def change
    add_column :users, :is_temp, :boolean, default: true
  end
end
