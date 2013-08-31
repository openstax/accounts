class CreatePeople < ActiveRecord::Migration
  def change
    create_table :people do |t|
      t.timestamps
    end

    add_column :users, :person_id, :integer, :null => true
  end
end
