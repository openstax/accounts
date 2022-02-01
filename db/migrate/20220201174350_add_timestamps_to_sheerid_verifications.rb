class AddTimestampsToSheeridVerifications < ActiveRecord::Migration[5.2]
  def change
    # all SheeridVerifications before this migration will have invalid timestamps unfortunately...
    add_timestamps(:sheerid_verifications, default: -> { "CURRENT_TIMESTAMP" })
  end
end
