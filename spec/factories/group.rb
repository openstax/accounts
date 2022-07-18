FactoryBot.define do

  factory :group do
    name { nil }
    is_public { false }

    transient do
      members_count { 0 }
      owners_count { 0 }
    end
  end
end
