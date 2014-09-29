# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :group_owner do
    group
    user
  end
end
