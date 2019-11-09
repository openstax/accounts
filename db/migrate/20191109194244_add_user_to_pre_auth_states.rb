class AddUserToPreAuthStates < ActiveRecord::Migration[5.2]
  def change
    add_reference :pre_auth_states, :user, index: true
  end
end
