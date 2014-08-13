require 'spec_helper'

describe Group do

  let!(:user_1) { FactoryGirl.create(:user) }
  let!(:user_2) { FactoryGirl.create(:user) }

  let!(:group_1) { FactoryGirl.create(:group) }
  let!(:group_2) { FactoryGirl.create(:group) }
  
  context 'validation' do
    it 'must have a unique name, if present' do
      group_1.name = nil
      group_1.save!
      group_1.name = 'MyGroup'
      group_1.save!

      group_3 = FactoryGirl.build(:group, name: group_1.name)
      expect(group_3).not_to be_valid
      expect(group_3.errors.messages[:name]).to eq(["has already been taken"])

      group_3.name = nil
      expect(group_3).to be_valid
    end
  end

  it 'can have members added' do
    expect(group_1.has_member?(user_1)).to eq(false)

    group_1.add_member(user_1)
    group_1.save!
    group_1.reload

    expect(group_1.has_member?(user_1)).to eq(true)
    expect(group_1.has_member?(user_2)).to eq(false)

    group_1.add_member(user_2)
    group_1.reload

    expect(group_1.has_member?(user_2)).to eq(true)
  end

  it 'can find members in nested groups' do
    group_2.add_member(user_2)
    expect(group_1.has_member?(user_1)).to eq(false)
    expect(group_1.has_member?(user_2)).to eq(false)
    expect(group_2.has_member?(user_2)).to eq(true)

    FactoryGirl.create(:group_nesting, container_group: group_1, member_group: group_2)
    group_1.reload

    expect(group_1.has_member?(user_1)).to eq(false)
    expect(group_1.has_member?(user_2)).to eq(true)

    group_2.add_member(user_1)
    group_2.reload

    expect(group_2.has_member?(user_1)).to eq(true)

    group_1.reload
    expect(group_1.has_member?(user_1)).to eq(true)
  end

end
