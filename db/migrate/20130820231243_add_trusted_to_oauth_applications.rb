class AddTrustedToOauthApplications < ActiveRecord::Migration[4.2]
  def change
    add_column :oauth_applications, :trusted, :boolean, default: false
  end
end
