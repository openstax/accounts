class CreateApplicationUsers < ActiveRecord::Migration
  def change
    create_table :application_users do |t|
      t.integer :application_id, null: false
      t.integer :user_id, null: false
      t.integer :default_contact_info_id

      t.timestamps
    end

    add_index :application_users, [:user_id, :application_id], unique: true
    add_index :application_users, :application_id
    add_index :application_users, :default_contact_info_id
  end
end
