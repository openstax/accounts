require 'rails_helper'

describe GroupOwner do
  let!(:group_owner) { FactoryBot.build(:group_owner) }

  context 'validation' do
    it 'must have a valid group' do
      group_owner.group = nil
      expect(group_owner).not_to be_valid
      expect(group_owner).to have_error(:group, :blank)
    end

    it 'must have a valid user' do
      group_owner.user = nil
      expect(group_owner).not_to be_valid
      expect(group_owner).to have_error(:user, :blank)
    end

    it 'must have a unique user for each group' do
      group_owner.save!
      group_owner2 = FactoryBot.build(:group_owner, group: group_owner.group,
                                                     user: group_owner.user)
      expect(group_owner2).not_to be_valid
      expect(group_owner2).to have_error(:user_id, :taken)

      group_owner2.user = FactoryBot.build(:user)
      expect(group_owner2).to be_valid
    end
  end

end
