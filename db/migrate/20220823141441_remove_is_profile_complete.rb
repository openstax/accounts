class RemoveIsProfileComplete < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :is_profile_complete, :boolean
  end
end
