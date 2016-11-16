class AddSelfReportedSchoolToUser < ActiveRecord::Migration
  def change
    add_column :users, :self_reported_school, :string
  end
end
