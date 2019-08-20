class AddFullNameToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :full_name, :string
  end
end
