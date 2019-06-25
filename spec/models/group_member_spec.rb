require 'rails_helper'

describe GroupMember do
  let!(:group_member) { FactoryBot.build(:group_member) }

  context 'validation' do
    it 'must have a valid group' do
      group_member.group = nil
      expect(group_member).not_to be_valid
      expect(group_member).to have_error(:group, :blank)
    end

    it 'must have a valid user' do
      group_member.user = nil
      expect(group_member).not_to be_valid
      expect(group_member).to have_error(:user, :blank)
    end

    it 'must have a unique user for each group' do
      group_member.save!
      group_member2 = FactoryBot.build(:group_member, group: group_member.group,
                                                       user: group_member.user)
      expect(group_member2).not_to be_valid
      expect(group_member2).to have_error(:user_id, :taken)

      group_member2.user = FactoryBot.build(:user)
      expect(group_member2).to be_valid
    end
  end

end
