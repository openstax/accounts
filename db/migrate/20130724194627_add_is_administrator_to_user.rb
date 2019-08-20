class AddIsAdministratorToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :is_administrator, :boolean, default: false
  end
end
