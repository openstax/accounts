class AddUserSearchIndices < ActiveRecord::Migration
  def change
    remove_index :users, :username
    add_index :users, :username, unique: true, case_sensitive: false
    add_index :users, :first_name, case_sensitive: false
    add_index :users, :last_name, case_sensitive: false
    add_index :users, :full_name, case_sensitive: false
  end
end
