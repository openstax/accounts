FactoryBot.define do
  factory :salesforce_drift_finding do
    category { 'sf_orphan_contact' }
    salesforce_record_type { 'Contact' }
    salesforce_record_id { SecureRandom.hex(8) }
    details { {} }
    first_seen_at { Time.current }
    last_seen_at { Time.current }
  end
end
