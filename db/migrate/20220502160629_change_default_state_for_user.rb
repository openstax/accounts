class ChangeDefaultStateForUser < ActiveRecord::Migration[5.2]
  def change
    change_column_default(:users, :state, :incomplete_signup)
  end
end
