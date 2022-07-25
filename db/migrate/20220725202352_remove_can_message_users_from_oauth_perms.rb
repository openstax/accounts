class RemoveCanMessageUsersFromOauthPerms < ActiveRecord::Migration[5.2]
  def change
    remove_column :oauth_applications, :can_message_users, :boolean
  end
end
