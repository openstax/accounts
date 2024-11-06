class AddDeleteFlagToUser < ActiveRecord::Migration[5.2]
  def change
    unless column_exists?(:users, :is_deleted)
      add_column :users, :is_deleted, :boolean
    end
  end
end
