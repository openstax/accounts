FactoryBot.define do
  factory :doorkeeper_application, :class => Doorkeeper::Application do
    sequence(:name){ |n| "Application #{n}" }
    redirect_uri { "https://app.com/callback" }
    email_from_address { 'app@app.com' }
    email_subject_prefix { '[Application]' }
    skip_terms { false }
    uid { SecureRandom.hex(8) }

    trait :trusted do
      can_access_private_user_data { true }
      can_find_or_create_accounts { true }
      can_message_users { true }
      can_skip_oauth_screen { true }
    end
  end
end
