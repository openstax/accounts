class RemoveNewflowFlag < ActiveRecord::Migration[5.2]
  def change
    remove_column(:users, :is_newflow)
  end
end
