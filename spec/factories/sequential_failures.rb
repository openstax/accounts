# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :sequential_failure do
    type 1
    reference "MyString"
    length 1
  end
end
