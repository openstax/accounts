class AddTrustedSignupStateFields < ActiveRecord::Migration
  def change
    add_column :signup_states, :trusted_data, :json
    add_column :users, :trusted_signup_data, :json
  end
end
