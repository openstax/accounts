class RemoveNeedsSync < ActiveRecord::Migration[5.2]
  def change
    remove_column(:users, :needs_sync)
  end
end
