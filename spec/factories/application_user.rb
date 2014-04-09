FactoryGirl.define do
  factory :application_user do
    association :application, factory: :doorkeeper_application
    user
  end
end
