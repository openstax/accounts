class AddApplicationIdAndRolesIndexToApplicationUsers < ActiveRecord::Migration[6.1]
  def change
    add_index :application_users, [:application_id, :roles, :user_id], where: "roles <> '{}'"
    remove_index :application_users, :application_id
  end
end
