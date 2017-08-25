class AddNamesToSignupState < ActiveRecord::Migration
  def change
    add_column :signup_states, :trusted_data, :json, default: {}
    execute 'update signup_states set trusted_data = \'{}\''
  end
end
