FactoryGirl.define do
  factory :application_user do
    ignore do
      username { SecureRandom.hex(3) }
      first_name nil
      last_name nil
    end

    association :application, factory: :doorkeeper_application
    user { FactoryGirl.build(:user, :username => username,
                                    :first_name => first_name,
                                    :last_name => last_name) }
    unread_updates 1

    factory :application_user_with_emails do
      ignore do
        username { SecureRandom.hex(3) }
        first_name nil
        last_name nil
        emails_count 2
      end

      user { FactoryGirl.build(:user, :username => username,
                                      :first_name => first_name,
                                      :last_name => last_name) }

      after(:build) do |application_user, evaluator|
        evaluator.emails_count.times do
          application_user.user.contact_infos << FactoryGirl.build(:email_address)
        end
      end
    end

  end
end
