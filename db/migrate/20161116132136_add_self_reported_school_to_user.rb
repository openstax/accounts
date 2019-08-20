class AddSelfReportedSchoolToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :self_reported_school, :string
  end
end
