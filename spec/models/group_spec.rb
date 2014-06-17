require 'spec_helper'

describe Group do

  let!(:group) { FactoryGirl.build(:group, users_count: 0) }

  let!(:user_1) { FactoryGirl.create(:user) }
  let!(:user_2) { FactoryGirl.create(:user) }
  let!(:user_3) { FactoryGirl.create(:user) }
  
  context 'validation' do
    it 'must have members' do
      expect(group).not_to be_valid
      expect(group.errors.messages[:group_users]).to eq(["can't be blank"])
    end

  end

  context 'members' do
    it 'adds members to the group' do
      expect(group.has_member?(user_1)).to eq(false)
      expect(group.has_manager?(user_1)).to eq(false)
      expect(group.has_owner?(user_1)).to eq(false)

      group.add_user(user_1)

      expect(group).to be_valid
      group.save!
      group.reload

      expect(group.has_member?(user_1)).to eq(true)
      expect(group.has_manager?(user_1)).to eq(true)
      expect(group.has_owner?(user_1)).to eq(true)

      expect(group.has_member?(user_2)).to eq(false)
      expect(group.has_manager?(user_2)).to eq(false)
      expect(group.has_owner?(user_2)).to eq(false)

      group.add_user(user_2)
      group.reload

      expect(group.has_member?(user_2)).to eq(true)
      expect(group.has_manager?(user_2)).to eq(false)
      expect(group.has_owner?(user_2)).to eq(false)

      expect(group.has_member?(user_3)).to eq(false)
      expect(group.has_manager?(user_3)).to eq(false)
      expect(group.has_owner?(user_3)).to eq(false)

      group.add_user(user_3, GroupUser::MANAGER)
      group.reload

      expect(group.has_member?(user_3)).to eq(true)
      expect(group.has_manager?(user_3)).to eq(true)
      expect(group.has_owner?(user_3)).to eq(false)
    end
  end

  context 'maintenance' do
    it 'removes empty groups' do
      group.add_user(user_1)
      group.save!
      expect(group.persisted?).to eq(true)
      group.maintenance
      expect(group.persisted?).to eq(true)
      group.group_users.first.destroy
      expect(group.persisted?).to eq(false)
    end

    it 'makes the first user an owner if no owners and no managers' do
      group.add_user(user_1)
      group.save!
      expect(group.group_users.first.access_level).to eq(GroupUser::OWNER)
      group.add_user(user_2)
      expect(group.group_users.last.access_level).to eq(GroupUser::MEMBER)
      group.group_users.first.destroy
      expect(group.group_users.last.access_level).to eq(GroupUser::OWNER)
    end

    it 'makes the first manager an owner if no owners' do
      group.add_user(user_1)
      group.save!
      expect(group.group_users.first.access_level).to eq(GroupUser::OWNER)
      group.add_user(user_2)
      expect(group.group_users.last.access_level).to eq(GroupUser::MEMBER)
      group.add_user(user_3, GroupUser::MANAGER)
      expect(group.group_users.last.access_level).to eq(GroupUser::MANAGER)
      group.group_users.first.destroy
      expect(group.group_users.first.access_level).to eq(GroupUser::MEMBER)
      expect(group.group_users.last.access_level).to eq(GroupUser::OWNER)
    end
  end

end
