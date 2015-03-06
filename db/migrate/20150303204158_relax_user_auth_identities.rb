class RelaxUserAuthIdentities < ActiveRecord::Migration
  def up
    # While these seem identical, the original index is :unique
    remove_index :authentications, name: 'index_authentications_on_user_id_scoped'

    add_index :authentications, [:user_id, :provider],
              :name => 'index_authentications_on_user_id_scoped'
  end

  def down
    remove_index :authentications, name: 'index_authentications_on_user_id_scoped'

    # This may fail if there have been any non-uniqe records added
    add_index :authentications,
              [:user_id, :provider],
              :name => 'index_authentications_on_user_id_scoped',
              :unique => true
  end
end
