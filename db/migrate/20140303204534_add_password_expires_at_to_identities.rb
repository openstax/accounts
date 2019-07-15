class AddPasswordExpiresAtToIdentities < ActiveRecord::Migration[4.2]
  def change
    add_column :identities, :password_expires_at, :datetime
  end
end
