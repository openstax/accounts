FactoryBot.define do
  factory :doorkeeper_access_token, class: Doorkeeper::AccessToken do
    association :application, factory: :doorkeeper_application
    expires_in { 2.hours }
  end
end
