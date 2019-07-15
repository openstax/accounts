class DropPasswordResetCodes < ActiveRecord::Migration[4.2]
  def change
    drop_table :password_reset_codes
  end
end
