class CreateUserExternalUuids < ActiveRecord::Migration
  def change
    create_table :user_external_uuids do |t|
      t.references :user, null: false
      t.string :uuid, null: false, index: true, unique: true
      t.timestamps null: false
    end
  end
end
