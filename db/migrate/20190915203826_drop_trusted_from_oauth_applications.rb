class DropTrustedFromOauthApplications < ActiveRecord::Migration[5.2]
  def up
    remove_column :oauth_applications, :trusted
  end

  def down
    add_column :oauth_applications, :trusted, :boolean, default: false
  end
end
