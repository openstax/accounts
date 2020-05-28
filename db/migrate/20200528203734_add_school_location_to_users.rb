class AddSchoolLocationToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :school_location, :integer, default: 0, null: false
  end
end
