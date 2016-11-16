class CreateSignupContactInfos < ActiveRecord::Migration
  def change
    create_table :signup_contact_infos do |t|
      t.integer :kind, null: false, default: 0
      t.index :kind
      t.string :value, null: false
      t.boolean :verified, default: false
      t.string :confirmation_code
      t.string :confirmation_pin
      t.datetime :confirmation_sent_at

      t.timestamps null: false
    end
  end
end
