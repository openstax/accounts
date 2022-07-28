class RemoveOauthGroups < ActiveRecord::Migration[5.2]
  def change
    drop_table :application_groups
    drop_table :groups
    drop_table :group_members
    drop_table :group_nestings
    drop_table :group_owners
  end
end
