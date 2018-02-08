class NullIpAddress < ActiveRecord::Migration
  def change
    change_column_null(:security_logs, :remote_ip, true)
  end
end
