class DropPeople < ActiveRecord::Migration
  def up
    drop_table :people
    remove_column :users, :person_id
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
