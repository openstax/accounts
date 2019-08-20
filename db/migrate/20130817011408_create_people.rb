class CreatePeople < ActiveRecord::Migration[4.2]
  def change
    create_table :people do |t|
      t.timestamps null: false
    end

    add_column :users, :person_id, :integer
  end
end
