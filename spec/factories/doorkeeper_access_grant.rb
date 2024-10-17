FactoryBot.define do
  factory :doorkeeper_access_grant, class: Doorkeeper::AccessGrant do
    sequence(:resource_owner_id) { |n| n }
    association :application, factory: :doorkeeper_application
    expires_in { 10.minutes }
    redirect_uri { 'urn:ietf:wg:oauth:2.0:oob' }
    scopes { 'all' }
  end
end
