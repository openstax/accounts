class AddEnhancedFieldsToSheeridVerifications < ActiveRecord::Migration[6.1]
  def change
    add_column :sheerid_verifications, :program_id, :string, if_not_exists: true
    add_column :sheerid_verifications, :segment, :string, if_not_exists: true
    add_column :sheerid_verifications, :sub_segment, :string, if_not_exists: true
    add_column :sheerid_verifications, :locale, :string, if_not_exists: true
    add_column :sheerid_verifications, :reward_code, :string, if_not_exists: true
    add_column :sheerid_verifications, :organization_id, :string, if_not_exists: true
    add_column :sheerid_verifications, :postal_code, :string, if_not_exists: true
    add_column :sheerid_verifications, :country, :string, if_not_exists: true
    add_column :sheerid_verifications, :phone_number, :string, if_not_exists: true
    add_column :sheerid_verifications, :birth_date, :string, if_not_exists: true
    add_column :sheerid_verifications, :ip_address, :string, if_not_exists: true
    add_column :sheerid_verifications, :device_fingerprint_hash, :string, if_not_exists: true
    add_column :sheerid_verifications, :doc_upload_rejection_count, :integer, default: 0, if_not_exists: true
    add_column :sheerid_verifications, :doc_upload_rejection_reasons, :text, array: true, default: [], if_not_exists: true
    add_column :sheerid_verifications, :error_ids, :text, array: true, default: [], if_not_exists: true
    add_column :sheerid_verifications, :metadata, :jsonb, default: {}, if_not_exists: true

    add_index :sheerid_verifications, :program_id, if_not_exists: true
    add_index :sheerid_verifications, :segment, if_not_exists: true
    add_index :sheerid_verifications, :organization_id, if_not_exists: true
    add_index :sheerid_verifications, :error_ids, using: :gin, if_not_exists: true
    add_index :sheerid_verifications, :metadata, using: :gin, if_not_exists: true
  end
end
