class AddExpectedStartSemesterToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :expected_start_semester, :string
  end
end
