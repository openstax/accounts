class RemoveSupportIdentifier < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :support_identifier
  end
end
