class AddExternalIdPushedAtToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :salesforce_student_external_id_pushed_at, :datetime, if_not_exists: true
    add_column :users, :salesforce_contact_external_id_pushed_at, :datetime, if_not_exists: true
  end
end
