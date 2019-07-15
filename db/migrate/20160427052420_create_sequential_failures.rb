class CreateSequentialFailures < ActiveRecord::Migration[4.2]
  def change
    create_table :sequential_failures do |t|
      t.integer :kind, null: false
      t.string :reference, null: false
      t.integer :length, default: 0

      t.timestamps null: false
    end

    add_index :sequential_failures, [:kind, :reference], unique: true
  end
end
