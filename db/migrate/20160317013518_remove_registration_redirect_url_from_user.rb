class RemoveRegistrationRedirectUrlFromUser < ActiveRecord::Migration
  def up
    remove_column :users, :registration_redirect_url
  end

  def down
    add_column :users, :registration_redirect_url, :text
  end
end
