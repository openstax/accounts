class AddUsersStateFlag < ActiveRecord::Migration
  def up
    add_column :users, :state, :string, default: 'temp'
    execute "update users set state='temp' where is_temp='t'"
    execute "update users set state='activated' where is_temp='f'"
    remove_column :users, :is_temp
  end

  def down
    add_column :users, :is_temp, :boolean, default: true
    # couldn't seem to get a case statement working on both PG and SQLite
    execute "update users set is_temp='t' where state  = 'temp'"
    execute "update users set is_temp='f' where state != 'temp'"
    remove_column :users, :state
  end
end
