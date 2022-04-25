class DropPasswordResetCodes < ActiveRecord::Migration[4.2]
  def change
    drop_table :password_reset_codes do |t|
      t.references :identity, null: false
      t.string :code, null: false
      t.datetime :expires_at

      t.timestamps null: false
    end
  end
end
