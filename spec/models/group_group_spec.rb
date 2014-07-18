require 'spec_helper'

describe GroupGroup do
  let!(:group_group) { FactoryGirl.build(:group_group) }
  
  context 'validation' do
    it 'must have a valid permitter group' do
      group_group.permitter_group = nil
      expect(group_group).not_to be_valid
      expect(group_group.errors.messages[:permitter_group]).to eq(["can't be blank"])
    end

    it 'must have a valid permitted group' do
      group_group.permitted_group = nil
      expect(group_group).not_to be_valid
      expect(group_group.errors.messages[:permitted_group]).to eq(["can't be blank"])
    end

    it 'must have a valid role' do
      group_group.role = nil
      expect(group_group).not_to be_valid
      expect(group_group.errors.messages[:role]).to eq(["can't be blank"])
    end

    it 'must not accept the member role' do
      group_group.role = 'member'
      expect(group_group).not_to be_valid
      expect(group_group.errors.messages[:role]).to eq(["is not an allowed role"])
    end

    it 'must have a unique user for each group and role' do
      group_group.save!
      group_group2 = FactoryGirl.build(:group_group,
                                       permitter_group: group_group.permitter_group,
                                       permitted_group: group_group.permitted_group)
      expect(group_group2).not_to be_valid
      expect(group_group2.errors.messages[:permitted_group_id]).to(
        eq(["has already been taken"]))

      group_group2.role = :owner
      expect(group_group2).to be_valid
    end
  end

end
