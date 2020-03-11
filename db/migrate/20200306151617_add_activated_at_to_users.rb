class AddActivatedAtToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :activated_at, :timestamp, after: 'state'
  end
end
