class CreateResetCodes < ActiveRecord::Migration
  def change
    create_table :reset_codes do |t|
      t.references :identity, null: false
      t.string :code, null: false
      t.datetime :expires_at

      t.timestamps
    end

    add_index :reset_codes, :identity_id, unique: true
    add_index :reset_codes, :code, unique: true
  end
end
