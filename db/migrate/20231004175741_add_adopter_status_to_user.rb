class AddAdopterStatusToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :adopter_status, :string
  end
end
