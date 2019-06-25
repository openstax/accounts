FactoryBot.define do
  factory :application_group do

    transient do
      name { SecureRandom.hex(3) }
      is_public { false }
    end

    association :application, factory: :doorkeeper_application
    group { FactoryBot.build(:group, name: name,
                                      :is_public => is_public) }
    unread_updates { 1 }

  end
end
