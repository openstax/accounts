class AddConsentPreferencesToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :consent_preferences, :jsonb
  end
end
