class AddSavingsToAdoptions < ActiveRecord::Migration[6.0]
  def change
    add_column :adoptions, :savings, :decimal, precision: 14, scale: 2
  end
end
