# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :group_supergroup_permission do
    group nil
    supergroup nil
    permission "MyString"
  end
end
