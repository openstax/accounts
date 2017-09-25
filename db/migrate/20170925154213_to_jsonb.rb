class ToJsonb < ActiveRecord::Migration
  def change
    change_column :signup_states, :trusted_data, :jsonb
    change_column :users, :trusted_signup_data, :jsonb
  end
end
