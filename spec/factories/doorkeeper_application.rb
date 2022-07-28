FactoryBot.define do
  factory :doorkeeper_application, :class => Doorkeeper::Application, aliases: [:application] do
    sequence(:name){ |n| "Application #{n}" }
    redirect_uri { "https://app.com/callback" }
    owner_id { FactoryBot.build(:user) }
    email_from_address { 'app@app.com' }
    email_subject_prefix { '[Application]' }
    skip_terms { false }
    uid { Doorkeeper::OAuth::Helpers::UniqueToken.generate }

    trait :trusted do
      can_access_private_user_data { true }
      can_find_or_create_accounts { true }
      confidential { false }
      can_skip_oauth_screen { true }
    end
  end
end
