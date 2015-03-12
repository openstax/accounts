class RelaxUserAuthIdentities < ActiveRecord::Migration
  def up
    # Remove unique index that was on [:user_id,:provider], which prevented multiple authentications from same provider
    remove_index :authentications, name: 'index_authentications_on_user_id_scoped'

    # Replace it with unique index on that also includes the provider's uid field.
    # This will allow multiple authentications from the same provider, as long as
    # they aren't referring to the same account at the provider.
    add_index :authentications, [:user_id, :provider, :uid],
              name: 'index_authentications_on_provider_uid_scoped'
  end

  def down
    remove_index :authentications, name: 'index_authentications_on_provider_uid_scoped'

    # This will fail if there have been any non-unique records added
    add_index :authentications,
              [:user_id, :provider],
              name:   'index_authentications_on_user_id_scoped',
              unique: true
  end
end
