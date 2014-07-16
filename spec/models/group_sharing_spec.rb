require 'spec_helper'

describe GroupSharing do
  let!(:group_sharing) { FactoryGirl.build(:group_sharing) }

  context 'validation' do
    it 'must have a valid group' do
      group_sharing.group = nil
      expect(group_sharing).not_to be_valid
      expect(group_sharing.errors.messages[:group]).to eq(["can't be blank"])
    end

    it 'must have a valid shared_with' do
      group_sharing.shared_with = nil
      expect(group_sharing).not_to be_valid
      expect(group_sharing.errors.messages[:shared_with]).to eq(["can't be blank"])
    end

    it 'must have a unique group for each shared_with' do
      group_sharing.save!
      group_sharing_2 = FactoryGirl.build(:group_sharing,
                                          group: group_sharing.group,
                                          shared_with: group_sharing.shared_with)
      expect(group_sharing_2).not_to be_valid
      expect(group_sharing_2.errors.messages[:group_id]).to(
        eq(["has already been taken"]))
    end
  end

end
