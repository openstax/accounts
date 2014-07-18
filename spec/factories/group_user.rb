FactoryGirl.define do

  factory :group_user do
    group
    user
    role 'member'
  end

end
