class AddFineGrainedAccessToOauthApplications < ActiveRecord::Migration[5.2]
  def up
    add_column :oauth_applications, :can_access_private_user_data, :boolean, default: false
    execute "update oauth_applications set can_access_private_user_data='t' where trusted  = 't'"

    add_column :oauth_applications, :can_find_or_create_accounts, :boolean, default: false
    execute "update oauth_applications set can_find_or_create_accounts='t' where trusted  = 't'"

    add_column :oauth_applications, :can_message_users, :boolean, default: false
    execute "update oauth_applications set can_message_users='t' where trusted  = 't'"

    add_column :oauth_applications, :can_skip_oauth_screen, :boolean, default: false
    execute "update oauth_applications set can_skip_oauth_screen='t' where trusted  = 't'"
  end

  def down
    remove_column :oauth_applications, :can_access_private_user_data
    remove_column :oauth_applications, :can_find_or_create_accounts
    remove_column :oauth_applications, :can_message_users
    remove_column :oauth_applications, :can_skip_oauth_screen
  end
end
