FactoryBot.define do
  factory :school do
    salesforce_id       { "0010v0#{SecureRandom.alphanumeric(9)}" }
    name                { Faker::Company.name }
    city                { Faker::Address.city }
    state               { [ Faker::Address.state, Faker::Address.state_abbr ].sample }
    sheerid_school_name { "#{name} (#{city}, #{state})" }
    type                    do
      [
        'College/University (4)',
        'Technical/Community College (2)',
        'Career School/For-Profit (2)',
        'For-Profit Tutoring',
        'High School',
        'Elementary School',
        'Middle/Junior High School',
        'K-12 School',
        'Other',
        'Home School'
      ].sample
    end
    location                { [ 'Domestic', 'Foreign' ].sample }
    is_kip                  { [ true, false ].sample }
    is_child_of_kip         { [ true, false ].sample }
  end
end
