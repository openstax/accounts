class AddTimestampsToSheeridVerifications < ActiveRecord::Migration[5.2]
  def change
    add_timestamps(:sheerid_verifications)
  end
end
