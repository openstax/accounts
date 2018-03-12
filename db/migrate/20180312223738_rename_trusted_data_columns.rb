class RenameTrustedDataColumns < ActiveRecord::Migration
  def change
    rename_column :signup_states, :trusted_data, :signed_data
    rename_column :users, :trusted_signup_data, :signed_external_data
  end
end
