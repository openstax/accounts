class CreateSchools < ActiveRecord::Migration[5.2]
  def change
    create_table :schools do |t|
      t.string :salesforce_id,       null: false, index: { unique: true }
      t.string :name,                null: false
      t.string :type,                null: false
      t.string :location,            null: false
      t.string :sheerid_school_name, index: true
      t.boolean :is_kip,             null: false
      t.boolean :is_child_of_kip,    null: false

      t.timestamps
    end
  end
end
