class CreateSalesforceUsers < ActiveRecord::Migration
  def change
    create_table :salesforce_users do |t|
      t.string :name
      t.string :uid, null: false
      t.string :oauth_token, null: false
      t.string :refresh_token, null: false
      t.string :instance_url, null: false
    end
  end
end
