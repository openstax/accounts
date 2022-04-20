class AddIsSchoolIssuedToContactInfos < ActiveRecord::Migration[5.2]
  def change
    add_column :contact_infos, :is_school_issued, :boolean,
comment: 'User claims to be a school-issued email address'
  end
end
