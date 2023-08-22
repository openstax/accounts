class AddRolesToApplicationUsers < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    # Try not to lock the entire table
    add_column :application_users, :roles, :string, array: true
    change_column_default :application_users, :roles, []
    loop do
      ids = ApplicationUser.where(roles: nil).limit(1000).pluck(:id)
      break if ids.empty?
      ApplicationUser.where(id: ids).update_all(roles: [])
    end
    change_column_null :application_users, :roles, false
  end

  def down
    remove_column :application_users, :roles
  end
end
