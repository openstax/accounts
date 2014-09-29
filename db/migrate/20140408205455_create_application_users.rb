class CreateApplicationUsers < ActiveRecord::Migration
  def change
    create_table :application_users do |t|
      t.references :application, null: false
      t.references :user, null: false
      t.references :default_contact_info

      t.timestamps
    end

    add_index :application_users, [:user_id, :application_id], unique: true
    add_index :application_users, :application_id
    add_index :application_users, :default_contact_info_id
  end
end
