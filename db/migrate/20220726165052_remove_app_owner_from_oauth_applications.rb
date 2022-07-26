class RemoveAppOwnerFromOauthApplications < ActiveRecord::Migration[5.2]
  def change
    # oauth_applications
    remove_column :oauth_applications, :owner_id
    remove_column :oauth_applications, :owner_type
  end
end
