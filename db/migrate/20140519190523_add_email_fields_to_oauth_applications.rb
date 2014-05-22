class AddEmailFieldsToOauthApplications < ActiveRecord::Migration
  def change
    add_column :oauth_applications, :email_from_address, :string,
                                    null: false, default: ''

    add_column :oauth_applications, :email_subject_prefix, :string,
                                    null: false, default: ''
  end
end
