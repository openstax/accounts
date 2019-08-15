class AddUserSearchIndices < ActiveRecord::Migration[4.2]
  change_table :users do |t|
    t.index 'lower(username)', name: 'index_users_on_username_case_insensitive'
    t.index 'lower(first_name)', name: 'index_users_on_first_name'
    t.index 'lower(last_name)', name: 'index_users_on_last_name'
    t.index 'lower(full_name)'
  end
end
