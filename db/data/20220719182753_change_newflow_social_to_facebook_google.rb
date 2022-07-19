# frozen_string_literal: true

class ChangeNewflowSocialToFacebookGoogle < ActiveRecord::Migration[5.2]
  def up
    Authentication.where(provider: 'facebooknewflow').each do |auth|
      auth.provider = 'facebook'
    end

    Authentication.where(provider: 'googlenewflow').each do |auth|
      auth.provider = 'google_oath2'
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
