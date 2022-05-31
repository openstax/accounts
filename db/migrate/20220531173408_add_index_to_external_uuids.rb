class AddIndexToExternalUuids < ActiveRecord::Migration[5.2]
  def change
    remove_index :user_external_uuids, [:uuid]
    add_index :user_external_uuids, [:uuid], unique: true
  end
end
