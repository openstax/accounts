class RemovePreAuthStates < ActiveRecord::Migration[5.2]
  def change
    drop_table(:pre_auth_states) if table_exists?(:pre_auth_states)
  end
end
