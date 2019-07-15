class AddSchoolTypeToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :school_type, :integer, null: false, default: 0
    add_index :users, :school_type
  end
end
