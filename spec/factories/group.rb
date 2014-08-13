FactoryGirl.define do

  factory :group do
    name nil
    is_public false

    ignore do
      members_count 1
      owners_count 1
    end

    after(:build) do |group, evaluator|
      evaluator.members_count.times do
        group.group_members << FactoryGirl.build(:group_member, group: group)
      end

      evaluator.owners_count.times do
        group.group_owners << FactoryGirl.build(:group_owner, group: group)
      end
    end
  end

end
