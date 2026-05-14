class AddExpectedStartSemesterToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :expected_start_semester, :string
  end
end
