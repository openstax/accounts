class CreateIdentities < ActiveRecord::Migration[4.2]
  def change
    create_table :identities do |t|
      t.string :password_digest
      t.timestamps null: false
    end
  end
end
