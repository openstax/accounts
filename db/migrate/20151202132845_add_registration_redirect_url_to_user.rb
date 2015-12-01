class AddRegistrationRedirectUrlToUser < ActiveRecord::Migration
  def change
    # Used for storing the url the user came from when they sign up
    add_column :users, :registration_redirect_url, :text
  end
end
