class AddGrantTutorAccessToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :grant_tutor_access, :boolean
  end
end
