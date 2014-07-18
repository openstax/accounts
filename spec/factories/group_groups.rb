# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :group_group do
    association :permitter_group, factory: :group
    association :permitted_group, factory: :group
    role 'viewer'
  end
end
