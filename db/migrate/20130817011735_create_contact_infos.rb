class CreateContactInfos < ActiveRecord::Migration[4.2]
  def change
    create_table :contact_infos do |t|
      t.string :type
      t.string :value
      t.boolean :verified
      t.string :confirmation_code
      t.integer :user_id

      t.timestamps null: false
    end

    add_index :contact_infos, :user_id, name: "index_contact_infos_on_user_id"
    add_index :contact_infos, [:value, :user_id, :type],
              name: "index_contact_infos_on_value_user_id_type", unique: true
  end
end
