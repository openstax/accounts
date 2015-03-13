require 'spec_helper'

describe MergeUnclaimedUsers do
  context 'given an unclaimed account' do
    let(:unclaimed_user) { FactoryGirl.create :user, state: 'unclaimed' }

    it "is claimed when email matches" do
      AddEmailToUser.call('unclaimeduser@example.com', unclaimed_user)
      matching_user = FactoryGirl.create(:user)
      AddEmailToUser.call('unclaimeduser@example.com', matching_user)
      expect{
        MergeUnclaimedUsers.call(matching_user.contact_infos.first)
      }.to change(User,:count).by(-1)
      expect{
        unclaimed_user.reload
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
