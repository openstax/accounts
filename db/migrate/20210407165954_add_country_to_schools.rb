class AddCountryToSchools < ActiveRecord::Migration[5.2]
  def change
    add_column :schools, :country, :string, default: 'United States', null: false
  end
end
