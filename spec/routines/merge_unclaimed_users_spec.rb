require 'rails_helper'

describe MergeUnclaimedUsers do

  context 'given an unclaimed account' do
    let!(:unclaimed_user) do
      u = FactoryBot.create :user, state: 'unclaimed'
      CreateEmailForUser.call('unclaimeduser@example.com', u)
      u
    end
    let!(:matching_user) do
      u = FactoryBot.create(:user)
      CreateEmailForUser.call('matched@example.com', u)
      u
    end
    let(:matching_email) do
      email = matching_user.contact_infos.last
      email.value = 'unclaimeduser@example.com'
      email.save(validate: false)
      email
    end

    it "is claimed when email matches" do
      expect do
        MergeUnclaimedUsers.call(matching_email)
      end.to change(User,:count).by(-1)
      expect{ unclaimed_user.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end


    it "moves associations to new account" do
      application = FactoryBot.create :doorkeeper_application
      application_user = FactoryBot.create :application_user,
                                            application: application, user: unclaimed_user

      MergeUnclaimedUsers.call(matching_email)
      expect(matching_user.application_users).to include(application_user)
    end

  end



end
