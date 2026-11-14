class AddPushedExternalIdToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :salesforce_student_pushed_external_id, :string, if_not_exists: true
    add_column :users, :salesforce_contact_pushed_external_id, :string, if_not_exists: true
  end
end
