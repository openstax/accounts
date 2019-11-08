class AddFirstNameToPreauthStates < ActiveRecord::Migration[5.2]
  def change
    add_column :pre_auth_states, :first_name, :string, default: ''
  end
end
