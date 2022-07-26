class RemoveOwnerFromGrants < ActiveRecord::Migration[5.2]
  def change
    remove_column :oauth_access_grants, :resource_owner_id
  end
end
