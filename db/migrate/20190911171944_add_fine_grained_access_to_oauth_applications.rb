class AddFineGrainedAccessToOauthApplications < ActiveRecord::Migration[5.2]
  def up
    add_column :oauth_applications, :can_access_private_user_data, :boolean, default: false,
null: false
    add_column :oauth_applications, :can_find_or_create_accounts, :boolean, default: false,
null: false
    add_column :oauth_applications, :can_message_users, :boolean, default: false, null: false
    add_column :oauth_applications, :can_skip_oauth_screen, :boolean, default: false, null: false

    Doorkeeper::Application.reset_column_information

    Doorkeeper::Application.where(trusted: true).update_all(
      can_access_private_user_data: true,
      can_find_or_create_accounts: true,
      can_message_users: true,
      can_skip_oauth_screen: true
    )
  end

  def down
    remove_column :oauth_applications, :can_access_private_user_data
    remove_column :oauth_applications, :can_find_or_create_accounts
    remove_column :oauth_applications, :can_message_users
    remove_column :oauth_applications, :can_skip_oauth_screen
  end
end
