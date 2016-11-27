class DropPasswordResetCodes < ActiveRecord::Migration
  def change
    drop_table :password_reset_codes
  end
end
