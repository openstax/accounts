FactoryGirl.define do
  factory :email_domain do
    value EmailAddress::WHITELIST.sample
    has_mx true
  end
end
