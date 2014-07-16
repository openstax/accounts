FactoryGirl.define do

  factory :group do
    name nil
    association :owner, factory: :user

    ignore do
      users_count 1
    end

    after(:build) do |group, evaluator|
      evaluator.users_count.times do
        group.group_users << FactoryGirl.build(:group_user, group: group)
      end
    end
  end

end
