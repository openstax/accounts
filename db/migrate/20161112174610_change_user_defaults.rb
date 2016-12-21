class ChangeUserDefaults < ActiveRecord::Migration
  def change
    change_column_default :users, :username, nil
    change_column_default :users, :state, "needs_profile"
  end
end
