FactoryBot.define do
  factory :sequential_failure do
    type { 1 }
    reference { "MyString" }
    length { 1 }
  end
end
