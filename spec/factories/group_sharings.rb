# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :group_sharing do
    group
    association :shared_with, factory: :user
  end
end
