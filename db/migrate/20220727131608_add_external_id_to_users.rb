class AddExternalIdToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :external_id, :string
  end
end
