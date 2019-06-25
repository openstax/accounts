FactoryBot.define do

  factory :group do
    name nil
    is_public false

    transient do
      members_count 0
      owners_count 0
    end

    after(:build) do |group, evaluator|
      evaluator.members_count.times do
        group.group_members << FactoryBot.build(:group_member, group: group)
      end

      evaluator.owners_count.times do
        group.group_owners << FactoryBot.build(:group_owner, group: group)
      end
    end
  end

end
