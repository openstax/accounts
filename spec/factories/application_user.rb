FactoryBot.define do
  factory :application_user do
    transient do
      username { SecureRandom.hex(3) }
      first_name Faker::Name.first_name
      last_name  Faker::Name.last_name
    end

    association :application, factory: :doorkeeper_application
    user { FactoryBot.build(:user, :username => username,
                                    :first_name => first_name,
                                    :last_name => last_name) }
    unread_updates 1

    factory :application_user_with_emails do
      transient do
        username { SecureRandom.hex(3) }
        first_name nil
        last_name nil
        emails_count 2
      end

      user { FactoryBot.build(:user, :username => username,
                                      :first_name => first_name,
                                      :last_name => last_name) }

      after(:build) do |application_user, evaluator|
        evaluator.emails_count.times do
          application_user.user.contact_infos << FactoryBot.build(:email_address)
        end
      end
    end

  end
end
