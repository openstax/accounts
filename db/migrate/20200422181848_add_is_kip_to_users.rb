class AddIsKipToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :is_kip, :boolean
  end
end
