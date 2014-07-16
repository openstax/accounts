require 'spec_helper'

describe Group do

  let!(:user_1) { FactoryGirl.create(:user) }
  let!(:user_2) { FactoryGirl.create(:user) }

  let!(:group_1) { FactoryGirl.build(:group) }
  let!(:group_2) { FactoryGirl.build(:group) }
  
  context 'validation' do
    it 'must have a unique name, if present' do
      group_1.name = 'MyGroup'
      group_1.save!
      group_2 = FactoryGirl.build(:group, name: group_1.name)
      expect(group_2).not_to be_valid
      expect(group_2.errors.messages[:name]).to eq(["has already been taken"])

      group_2.name = nil
      expect(group_2).to be_valid
    end
  end

  it 'can have members added' do
    expect(group_1).to be_valid
    expect(group_1.has_member?(user_1)).to eq(false)

    group_1.add_user(user_1)
    group_1.save!
    group_1.reload

    expect(group_1.has_member?(user_1)).to eq(true)
    expect(group_1.has_member?(user_2)).to eq(false)

    group_1.add_user(user_2)
    group_1.reload

    expect(group_1.has_member?(user_2)).to eq(true)
  end

  it 'can be shared' do
    expect(group_1).to be_valid
    expect(group_1.group_sharing_for(user_1)).to be_nil

    group_1.share_with(user_1)
    group_1.save!
    group_1.reload

    expect(group_1.group_sharing_for(user_1)).not_to be_nil
    expect(group_1.group_sharing_for(user_1).can_edit).to eq(false)
    expect(group_1.group_sharing_for(group_2)).to be_nil

    group_1.share_with(group_2, true)
    group_1.reload

    expect(group_1.group_sharing_for(group_2)).not_to be_nil
    expect(group_1.group_sharing_for(group_2).can_edit).to eq(true)
  end

end
