class CreateSchools < ActiveRecord::Migration[5.2]
  def change
    enable_extension :pg_trgm

    create_table :schools do |t|
      t.string :salesforce_id,       null: false, index: { unique: true }
      t.string :name,                null: false
      t.string :city
      t.string :state
      t.string :type
      t.string :location
      t.string :sheerid_school_name, index: true
      t.boolean :is_kip,             null: false
      t.boolean :is_child_of_kip,    null: false

      t.index [ :name, :city, :state ], using: :gist, opclass: :gist_trgm_ops

      t.timestamps
    end
  end
end
