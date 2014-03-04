class AddPasswordExpiresAtToIdentities < ActiveRecord::Migration
  def change
    add_column :identities, :password_expires_at, :datetime
  end
end
