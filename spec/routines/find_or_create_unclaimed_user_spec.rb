require 'spec_helper'

describe FindOrCreateUnclaimedUser do
  context 'given an email of existing user' do
    let(:user) { FactoryGirl.create :user, state: 'unclaimed' }

    it "is returned" do
      AddEmailToUser.call('unclaimeduser@example.com', user, already_verified: true)
      newuser = FindOrCreateUnclaimedUser.call('unclaimeduser@example.com').outputs.user
      expect(newuser).to eq(user)
    end
  end

  context "given a email that doesn't exist" do
    it "creates a new user with the email" do
      expect {
        newuser = FindOrCreateUnclaimedUser.call('anunusedemail@example.com').outputs.user
        expect(newuser.contact_infos.first.value).to eq('anunusedemail@example.com')
      }.to change(User,:count).by(1)
    end
  end

end
