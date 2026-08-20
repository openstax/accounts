class AddApplicationIdAndRolesIndexToApplicationUsers < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :application_users, [:application_id, :roles, :user_id],
              where: "roles <> '{}'", algorithm: :concurrently
    remove_index :application_users, :application_id, algorithm: :concurrently
  end
end
