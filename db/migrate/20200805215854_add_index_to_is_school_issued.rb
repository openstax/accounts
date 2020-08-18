class AddIndexToIsSchoolIssued < ActiveRecord::Migration[5.2]
  def change
    add_index :contact_infos, :is_school_issued
  end
end
