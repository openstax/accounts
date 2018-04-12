class AddSchoolTypeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :school_type, :integer, null: false, default: 0
    add_index :users, :school_type
  end
end
