class AddSourceApplicationToUsers < ActiveRecord::Migration[5.2]
  def change
    add_reference :oauth_applications, :source_application, index: true
  end
end
