class AddUsingOpenStaxToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :using_openstax, :boolean, default: false
  end
end
