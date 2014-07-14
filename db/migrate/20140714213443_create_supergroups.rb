class CreateSupergroups < ActiveRecord::Migration
  def change
    create_table :supergroups do |t|
      t.string :name, null: false
      t.references :application, null: false

      t.timestamps
    end

    add_index :supergroups, :application_id
  end
end
