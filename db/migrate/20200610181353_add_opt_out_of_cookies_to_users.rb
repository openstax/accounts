class AddOptOutOfCookiesToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :opt_out_of_cookies, :boolean, default: false
  end
end
