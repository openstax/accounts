require 'schema_plus_pg_indexes'
class AddUserSearchIndices < ActiveRecord::Migration
  def change
    add_index :users, :username, case_sensitive: false,
                                 name: 'index_users_on_username_case_insensitive'
    add_index :users, :first_name, case_sensitive: false
    add_index :users, :last_name, case_sensitive: false
    add_index :users, :full_name, case_sensitive: false
  end
end
