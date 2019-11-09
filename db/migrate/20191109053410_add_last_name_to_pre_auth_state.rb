class AddLastNameToPreAuthState < ActiveRecord::Migration[5.2]
  def change
    add_column :pre_auth_states, :last_name, :string, default: ''
  end
end
