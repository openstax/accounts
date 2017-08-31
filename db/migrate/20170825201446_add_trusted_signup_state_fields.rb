class AddTrustedSignupStateFields < ActiveRecord::Migration
  def change
    add_column :signup_states, :trusted_data, :jsonb
    add_column :users, :trusted_signup_data, :jsonb
  end
end
