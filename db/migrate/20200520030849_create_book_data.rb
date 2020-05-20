class CreateBookData < ActiveRecord::Migration[5.2]
  def change
    create_table :book_data do |t|
      t.json :titles, null: false
      t.json :subjects, null: false

      t.timestamps null: false
    end
  end
end
