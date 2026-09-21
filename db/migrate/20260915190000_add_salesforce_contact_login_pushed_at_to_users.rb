class AddSalesforceContactLoginPushedAtToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :salesforce_contact_login_pushed_at, :datetime

    add_index :users, %i[salesforce_contact_login_pushed_at last_signed_in_at],
              where: 'salesforce_contact_id IS NOT NULL',
              name: 'index_users_with_contact_by_login'
  end
end
