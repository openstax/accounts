class AddReceiveNewsletterAndSourceAppToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :receive_newsletter, :boolean
    add_reference :users, :source_application, foreign_key: { to_table: :oauth_applications }
  end
end
