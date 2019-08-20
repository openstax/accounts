class RemoveRegistrationRedirectUrlFromUser < ActiveRecord::Migration[4.2]
  def up
    remove_column :users, :registration_redirect_url
  end

  def down
    add_column :users, :registration_redirect_url, :text
  end
end
