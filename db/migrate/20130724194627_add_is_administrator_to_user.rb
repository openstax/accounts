class AddIsAdministratorToUser < ActiveRecord::Migration
  def change
    add_column :users, :is_administrator, :boolean, default: false
  end
end
