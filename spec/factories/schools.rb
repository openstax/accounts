FactoryBot.define do
  factory :school do
    salesforce_id   { SecureRandom.urlsafe_base64 }
    name            { Faker::Company.name }
    type            do
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
    location        { [ 'Domestic', 'Foreign' ].sample }
    is_kip          { [ true, false ].sample }
    is_child_of_kip { [ true, false ].sample }
  end
end
