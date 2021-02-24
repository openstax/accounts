class AddSchoolIdToUsers < ActiveRecord::Migration[5.2]
  def change
    add_reference :users, :school, foreign_key: true
  end
end
