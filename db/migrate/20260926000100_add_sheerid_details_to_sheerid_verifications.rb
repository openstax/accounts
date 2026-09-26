class AddSheeridDetailsToSheeridVerifications < ActiveRecord::Migration[6.1]
  def up
    add_column :sheerid_verifications, :error_ids, :jsonb, null: false, default: []
    add_column :sheerid_verifications, :rejection_reasons, :jsonb, null: false, default: []
    add_column :sheerid_verifications, :segment, :string
    add_column :sheerid_verifications, :last_response, :jsonb
    add_column :sheerid_verifications, :webhook_received_at, :datetime
    add_column :sheerid_verifications, :webhook_count, :integer, null: false, default: 0

    # verification_id was never unique before, and the old webhook's
    # find_or_initialize_by could race itself into duplicates. Keep the most
    # recently updated row for each id, which is the one carrying the last
    # step SheerID reported.
    execute <<~SQL
      DELETE FROM sheerid_verifications older
      USING sheerid_verifications newer
      WHERE older.verification_id = newer.verification_id
        AND (older.updated_at, older.id) < (newer.updated_at, newer.id)
    SQL

    add_index :sheerid_verifications, :verification_id, unique: true, if_not_exists: true
  end

  def down
    remove_index :sheerid_verifications, :verification_id, if_exists: true
    remove_column :sheerid_verifications, :webhook_count
    remove_column :sheerid_verifications, :webhook_received_at
    remove_column :sheerid_verifications, :last_response
    remove_column :sheerid_verifications, :segment
    remove_column :sheerid_verifications, :rejection_reasons
    remove_column :sheerid_verifications, :error_ids
  end
end
