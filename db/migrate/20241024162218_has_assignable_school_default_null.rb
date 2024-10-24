class HasAssignableSchoolDefaultNull < ActiveRecord::Migration[6.1]
  def change
    change_column_null :schools, :has_assignable_contacts, null: false, default: false
  end
end
