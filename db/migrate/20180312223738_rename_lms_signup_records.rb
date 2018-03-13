class RenameTrustedDataColumns < ActiveRecord::Migration
  def change
    rename_column :users, :trusted_signup_data, :signed_external_data

    rename_column :signup_states, :trusted_data, :signed_data
    rename_column :signup_states, :verified, :is_contact_info_verified
  end
end
