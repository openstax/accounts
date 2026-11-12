class AddAssignableIntegrationToSchools < ActiveRecord::Migration[6.1]
  def change
    add_column :schools, :assignable_integrated, :boolean, default: false, null: false
    add_column :schools, :assignable_integration_possible, :boolean, default: false, null: false
  end
end
