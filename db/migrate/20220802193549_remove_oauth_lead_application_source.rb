class RemoveOauthLeadApplicationSource < ActiveRecord::Migration[5.2]
  def change
    remove_column :oauth_applications, :lead_application_source
  end
end
