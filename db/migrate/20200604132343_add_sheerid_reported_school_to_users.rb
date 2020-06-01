class AddSheeridReportedSchoolToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :sheerid_reported_school, :string, after: :self_reported_school
  end
end
