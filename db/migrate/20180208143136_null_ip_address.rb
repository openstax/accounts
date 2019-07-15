class NullIpAddress < ActiveRecord::Migration[4.2]
  def change
    change_column_null(:security_logs, :remote_ip, true)
  end
end
