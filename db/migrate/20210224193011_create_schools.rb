class CreateSchools < ActiveRecord::Migration[5.2]
  def change
    create_table :schools do |t|
      t.string :salesforce_id,    null: false
      t.string :name,             null: false
      t.string :type,             null: false
      t.string :location,         null: false
      t.boolean :is_kip,          null: false
      t.boolean :is_child_of_kip, null: false

      t.timestamps
    end
  end
end
