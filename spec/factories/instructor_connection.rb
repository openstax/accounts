FactoryBot.define do
  factory :instructor_connection do
    student { FactoryBot.build(:user, role: :student) }
    instructor_name { Faker::Name.name }
    school_name { Faker::Company.name }
    status { 'unverified' }
  end
end
