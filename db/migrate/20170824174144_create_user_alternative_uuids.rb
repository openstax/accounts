class CreateUserAlternativeUuids < ActiveRecord::Migration
  def change
    create_table :user_alternative_uuids do |t|
      t.references :user, null: false
      t.string :uuid, null: false, index: true
      t.timestamps null: false
    end
  end
end
