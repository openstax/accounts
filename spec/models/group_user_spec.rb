require 'spec_helper'

describe GroupUser do
  let!(:group_user) { FactoryGirl.build(:group_user) }
  
  context 'validation' do
    it 'must have a valid group' do
      group_user.group = nil
      expect(group_user).not_to be_valid
      expect(group_user.errors.messages[:group]).to eq(["can't be blank"])
    end

    it 'must have a valid user' do
      group_user.user = nil
      expect(group_user).not_to be_valid
      expect(group_user.errors.messages[:user]).to eq(["can't be blank"])
    end

    it 'must have a valid role' do
      group_user.role = nil
      expect(group_user).not_to be_valid
      expect(group_user.errors.messages[:role]).to eq(["can't be blank"])
    end

    it 'must have a unique user for each group and role' do
      group_user.save!
      group_user2 = FactoryGirl.build(:group_user, group: group_user.group,
                                                   user: group_user.user)
      expect(group_user2).not_to be_valid
      expect(group_user2.errors.messages[:user_id]).to(
        eq(["has already been taken"]))

      group_user2.role = :owner
      expect(group_user2).to be_valid
    end
  end

end
