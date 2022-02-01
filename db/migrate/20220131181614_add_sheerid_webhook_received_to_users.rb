class AddSheeridWebhookReceivedToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :sheer_id_webhook_received, :boolean
  end
end
