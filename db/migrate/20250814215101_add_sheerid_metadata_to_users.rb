class AddSheeridMetadataToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :sheerid_program_id, :string, if_not_exists: true
    add_column :users, :sheerid_segment, :string, if_not_exists: true
    add_column :users, :sheerid_organization_id, :string, if_not_exists: true
    add_column :users, :sheerid_postal_code, :string, if_not_exists: true
    add_column :users, :sheerid_country, :string, if_not_exists: true
    add_column :users, :sheerid_phone_number, :string, if_not_exists: true
    add_column :users, :sheerid_birth_date, :string, if_not_exists: true
    add_column :users, :sheerid_ip_address, :string, if_not_exists: true
    add_column :users, :sheerid_device_fingerprint_hash, :string, if_not_exists: true
    add_column :users, :sheerid_doc_upload_rejection_count, :integer, default: 0, if_not_exists: true
    add_column :users, :sheerid_doc_upload_rejection_reasons, :text, array: true, default: [], if_not_exists: true
    add_column :users, :sheerid_error_ids, :text, array: true, default: [], if_not_exists: true
    add_column :users, :sheerid_metadata, :jsonb, default: {}, if_not_exists: true

    add_index :users, :sheerid_program_id, if_not_exists: true
    add_index :users, :sheerid_segment, if_not_exists: true
    add_index :users, :sheerid_organization_id, if_not_exists: true
    add_index :users, :sheerid_error_ids, using: :gin, if_not_exists: true
    add_index :users, :sheerid_metadata, using: :gin, if_not_exists: true
  end
end
