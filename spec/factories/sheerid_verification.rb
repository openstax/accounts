FactoryBot.define do
  factory :sheerid_verification do
    current_step { 'success' }
    email { Faker::Internet.free_email }
    verification_id { Faker::Internet.uuid }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    organization_name { Faker::Company.name }
  end
end
