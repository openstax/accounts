# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :group_owner do
    group
    user
  end
end
