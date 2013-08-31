FactoryGirl.define do
  factory :user do
    username { SecureRandom.hex(3) }

    trait :admin do
      is_administrator true
    end

    factory :user_with_person do
      person
    end

    factory :user_with_emails do
      ignore do
        emails_count 2
      end

      # Leaving this here to show how to do :create instead of :build
      # after(:create) do |user, evaluator|
      #   FactoryGirl.create_list(:email_address, evaluator.emails_count, user: user)
      # end

      after(:build) do |user, evaluator|
        evaluator.emails_count.times do 
          user.contact_infos << FactoryGirl.build(:email_address)
        end
      end
    end
  end
  
end