class DropSettings < ActiveRecord::Migration[5.2]
  def change
    if table_exists?(:settings)
      drop_table(:settings) do |t|
        t.string  :var,        null: false
        t.text    :value,      null: true
        t.timestamps
      end
    end
  end
end
