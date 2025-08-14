FactoryBot.define do
  factory :sheerid_verification do
    current_step do
      [ SheeridVerification::VERIFIED, SheeridVerification::REJECTED, 'pending' ].sample
    end
    email { Faker::Internet.email }
    verification_id { Faker::Internet.uuid }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    organization_name { Faker::Company.name }
    program_id { "5e150b86ce2a5a1d94874660" }
    segment { "teacher" }
    sub_segment { nil }
    locale { "en-US" }
    reward_code { "EXAMPLE-CODE" }
    organization_id { rand(1000..9999).to_s }
    postal_code { Faker::Address.zip_code }
    country { "United States" }
    phone_number { Faker::PhoneNumber.phone_number }
    birth_date { nil }
    ip_address { Faker::Internet.ip_v4_address }
    device_fingerprint_hash { nil }
    doc_upload_rejection_count { 0 }
    doc_upload_rejection_reasons { [] }
    error_ids { [] }
    metadata { { "marketConsentValue" => "false" } }
  end
end
