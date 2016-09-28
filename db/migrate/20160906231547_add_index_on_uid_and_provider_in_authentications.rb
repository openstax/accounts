class AddIndexOnUidAndProviderInAuthentications < ActiveRecord::Migration
  def change
    add_index :authentications,
              [:uid, :provider],
              name: 'index_authentications_on_uid_scoped',
              unique: true
  end
end
