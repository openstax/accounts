FactoryBot.define do
  factory :user do
    username { SecureRandom.hex(3) }
    state { User::ACTIVATED } # otherwise the default from DB will be to 'temp'
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name  }
    uuid { Faker::Internet.uuid }
    role { User::STUDENT_ROLE }
    school { FactoryBot.build(:school) }

    is_profile_complete { true }

    trait :admin do
      is_administrator { true }
    end

    factory :temp_user do
      state { 'temp' }
    end

    factory :new_social_user do
      state { 'new_social' }
    end

    factory :activated do
      state { 'activated' }
    end

    trait :terms_not_agreed do; end

    trait :terms_agreed do
      after(:create) do |user, evaluator|
        FinePrint::Contract.all.each do |contract|
          FinePrint.sign_contract(user, contract)
        end
      end
    end

    factory :user_with_emails do
      transient do
        emails_count { 2 }
      end

      # Leaving this here to show how to do :create instead of :build
      # after(:create) do |user, evaluator|
      #   FactoryBot.create_list(:email_address, evaluator.emails_count, user: user)
      # end

      after(:build) do |user, evaluator|
        evaluator.emails_count.times do
          # make sure build email with nil user so don't make extra unexpected users
          user.contact_infos << FactoryBot.build(:email_address, user: nil)
        end
      end
    end
  end

end
