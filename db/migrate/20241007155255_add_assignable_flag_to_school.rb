class AddAssignableFlagToSchool < ActiveRecord::Migration[5.2]
  def change
    add_column :schools, :has_assignable_contacts, :boolean
  end
end
