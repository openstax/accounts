class CreateSheeridVerifications < ActiveRecord::Migration[5.2]
  def change
    create_table :sheerid_verifications do |t|
      t.string :verification_id, null: false
      t.string :email, null: false
      t.string :current_step, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :organization_name, null: false

      t.timestamps
    end
  end
end
