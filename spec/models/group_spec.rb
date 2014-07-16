require 'spec_helper'

describe Group do

  let!(:group) { FactoryGirl.build(:group) }

  let!(:user_1) { FactoryGirl.create(:user) }
  let!(:user_2) { FactoryGirl.create(:user) }
  let!(:user_3) { FactoryGirl.create(:user) }
  
  context 'validation' do
    it 'must have a unique name, if present' do
      group.name = 'MyGroup'
      group.save!
      group_2 = FactoryGirl.build(:group, name: group.name)
      expect(group_2).not_to be_valid
      expect(group_2.errors.messages[:name]).to eq(["has already been taken"])

      group_2.name = nil
      expect(group_2).to be_valid
    end
  end

  it 'can have members added' do
    expect(group).to be_valid
    expect(group.has_member?(user_1)).to eq(false)

    group.add_user(user_1)
    group.save!
    group.reload

    expect(group.has_member?(user_1)).to eq(true)
    expect(group.has_member?(user_2)).to eq(false)

    group.add_user(user_2)
    group.reload

    expect(group.has_member?(user_2)).to eq(true)
  end

  it 'can be shared' do
    
  end

end
