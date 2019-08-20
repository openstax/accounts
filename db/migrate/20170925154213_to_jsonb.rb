class ToJsonb < ActiveRecord::Migration[4.2]
  def change
    change_column :signup_states, :trusted_data, :jsonb
    change_column :users, :trusted_signup_data, :jsonb
  end
end
