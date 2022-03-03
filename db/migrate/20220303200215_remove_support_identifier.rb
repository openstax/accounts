class RemoveSupportIdentifier < ActiveRecord::Migration[5.2]
  def change
    if column_exists? :users, :support_identifier
      remove_column :users, :support_identifier
    end
  end
end
