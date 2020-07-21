class RemovePresenceReqFromSheeridVerifications < ActiveRecord::Migration[5.2]
  def change
    change_column_null :sheerid_verifications, :email, true
    change_column_null :sheerid_verifications, :current_step, true
    change_column_null :sheerid_verifications, :first_name, true
    change_column_null :sheerid_verifications, :last_name, true
    change_column_null :sheerid_verifications, :organization_name, true
  end
end
