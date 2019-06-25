# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :group_nesting do
    association :container_group, factory: :group
    association :member_group, factory: :group
  end
end
