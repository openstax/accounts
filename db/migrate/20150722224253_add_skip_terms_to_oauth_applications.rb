class AddSkipTermsToOauthApplications < ActiveRecord::Migration[4.2]
  def change
    add_column :oauth_applications, :skip_terms, :boolean,
                                    default: false, null: false
  end
end
