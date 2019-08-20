class AddSuffixToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :suffix, :string
  end
end
