require 'spec_helper'

describe GroupMember do
  let!(:group_member) { FactoryGirl.build(:group_member) }
  
  context 'validation' do
    it 'must have a valid group' do
      group_member.group = nil
      expect(group_member).not_to be_valid
      expect(group_member.errors.messages[:group]).to eq(["can't be blank"])
    end

    it 'must have a valid user' do
      group_member.user = nil
      expect(group_member).not_to be_valid
      expect(group_member.errors.messages[:user]).to eq(["can't be blank"])
    end

    it 'must have a unique user for each group' do
      group_member.save!
      group_member2 = FactoryGirl.build(:group_member, group: group_member.group,
                                                       user: group_member.user)
      expect(group_member2).not_to be_valid
      expect(group_member2.errors.messages[:user_id]).to(
        eq(["has already been taken"]))

      group_member2.user = FactoryGirl.build(:user)
      expect(group_member2).to be_valid
    end
  end

end
