FactoryGirl.define do

  factory :group_user do
    group
    user
    access_level GroupUser::MEMBER
  end

end
