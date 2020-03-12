class AddIsNewflowToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :is_newflow, :boolean, default: false, null: false
  end
end
