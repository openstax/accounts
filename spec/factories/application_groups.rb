# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :application_group do
    application nil
    group nil
    unread_updates 1
  end
end
