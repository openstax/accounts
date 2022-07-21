# frozen_string_literal: true

class ChangeNewflowSocialToFacebookGoogle < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    Authentication.where(provider: 'facebooknewflow').each do |auth|
      auth.provider = 'facebook'
      auth.save
    end

    Authentication.where(provider: 'googlenewflow').each do |auth|
      auth.provider = 'google_oauth2'
      auth.save
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
