class RenameLmsLoginRecords < ActiveRecord::Migration[4.2]
  def change
    rename_column :users, :trusted_signup_data, :signed_external_data

    rename_table :signup_states, :pre_auth_states

    rename_column :pre_auth_states, :trusted_data, :signed_data
    rename_column :pre_auth_states, :verified, :is_contact_info_verified
  end
end
