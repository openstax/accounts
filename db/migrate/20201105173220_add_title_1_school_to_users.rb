class AddTitle1SchoolToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :title_1_school, :boolean
  end
end
