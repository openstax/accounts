class AddApplicationsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_reference :application_users, :applications, index: true
  end
end
