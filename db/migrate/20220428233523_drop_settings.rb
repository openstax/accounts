class DropSettings < ActiveRecord::Migration[5.2]
  def up
    if table_exists?(:settings)
      drop_table(:settings) do |t|
        t.string :var, null: false
        t.text :value, null: true
        t.timestamps
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
