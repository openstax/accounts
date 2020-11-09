class AddIsBRIUserToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :is_b_r_i_user, :boolean
  end
end
