class AddSheeridDetailsToSheeridVerifications < ActiveRecord::Migration[6.1]
  def change
    add_column :sheerid_verifications, :error_ids, :jsonb, null: false, default: []
    add_column :sheerid_verifications, :rejection_reasons, :jsonb, null: false, default: []
    add_column :sheerid_verifications, :segment, :string
    add_column :sheerid_verifications, :last_response, :jsonb
    add_column :sheerid_verifications, :webhook_received_at, :datetime
    add_column :sheerid_verifications, :webhook_count, :integer, null: false, default: 0

    add_index :sheerid_verifications, :verification_id, unique: true, if_not_exists: true
  end
end
