require 'rails_helper'

describe GroupNesting do

  let!(:group_1) { FactoryGirl.create(:group) }
  let!(:group_2) { FactoryGirl.create(:group) }
  let!(:group_3) { FactoryGirl.create(:group) }

  let!(:group_nesting_1) { FactoryGirl.build(:group_nesting) }
  let!(:group_nesting_2) { FactoryGirl.build(:group_nesting) }

  context 'validation' do
    it 'must have a unique member_group' do
      group_nesting_1.save!

      group_nesting_2.member_group = nil
      expect(group_nesting_2).not_to be_valid
      expect(group_nesting_2).to have_error(:member_group, :blank)

      group_nesting_2.member_group = group_nesting_1.member_group
      expect(group_nesting_2).not_to be_valid
      expect(group_nesting_2).to have_error(:member_group_id, :taken)
    end

    it 'must have a container_group' do
      group_nesting_2.container_group = nil
      expect(group_nesting_2).not_to be_valid
      expect(group_nesting_2).to have_error(:container_group, :blank)
    end

    it 'cannot nest groups in loops' do
      gn = FactoryGirl.build(:group_nesting, container_group: group_1, member_group: group_1)
      expect(gn).not_to be_valid
      expect(gn.errors.messages[:base]).to eq(["would create a loop"])

      FactoryGirl.create(:group_nesting, container_group: group_1, member_group: group_2)
      group_1.reload
      group_2.reload

      gn = FactoryGirl.build(:group_nesting, container_group: group_2, member_group: group_1)
      expect(gn).not_to be_valid
      expect(gn.errors.messages[:base]).to eq(["would create a loop"])

      FactoryGirl.create(:group_nesting, container_group: group_2, member_group: group_3)
      group_1.reload
      group_2.reload
      group_3.reload

      gn = FactoryGirl.build(:group_nesting, container_group: group_3, member_group: group_1)
      expect(gn).not_to be_valid
      expect(gn.errors.messages[:base]).to eq(["would create a loop"])
    end
  end

end
