class AddNeedsSyncToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :needs_sync, :boolean
  end
end
