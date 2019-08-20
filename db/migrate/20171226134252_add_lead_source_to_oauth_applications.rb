class AddLeadSourceToOauthApplications < ActiveRecord::Migration[4.2]
  def change
    add_column :oauth_applications, :lead_application_source, :string,
                                    null: false, default: ''
  end
end
