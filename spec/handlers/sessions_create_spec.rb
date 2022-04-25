# coding: utf-8
require 'rails_helper'

RSpec.describe SessionsCreate, type: :handler do

  context "logged in" do
    let(:current_user) { FactoryBot.create :user }
    before(:each) { user_state.sign_in!(current_user) }

    context "authentication already on current user" do
      before do
        FactoryBot.create(
          :authentication, provider: "facebook", uid: "blahuid", user: current_user
        )
      end

      it "returns :no_action" do
        result = handle(request: MockOmniauthRequest.new("facebook", "blahuid", {}))
        expect(result.outputs.status).to eq :no_action
      end
    end

    context "adding new authentication to account" do
      context "authentication is for a different user" do
        before do
          FactoryBot.create(:authentication, provider: "facebook",
                                              uid: "blahuid",
                                              user: FactoryBot.create(:user))
        end

        it "returns :authentication_taken" do
          result = handle(
            request: MockOmniauthRequest.new("facebook", "blahuid", {}, 'add' => 'true')
          )
          expect(result.outputs.status).to eq :authentication_taken
        end
      end

      context "authentication provider already on current user" do
        before do
          FactoryBot.create(:authentication, provider: "google_oauth2",
                                              uid: "uid_one",
                                              user: current_user)
        end

        it "returns :same_provider" do
          result = handle(
            request: MockOmniauthRequest.new("google_oauth2", "uid_two", {}, 'add' => 'true')
          )
          expect(result.outputs.status).to eq :same_provider
        end
      end

      context "user hasn't signed in recently enough to complete action" do
        before(:each) do
          SecurityLog.create! user: current_user, remote_ip: '127.0.0.1',
                              event_type: :sign_in_successful, event_data: {}
          Timecop.freeze(Time.zone.now + RequireRecentSignin::REAUTHENTICATE_AFTER)
        end

        it "returns :new_signin_required" do
          result = handle(
            request: MockOmniauthRequest.new("google_oauth2", "uid", {}, 'add' => 'true')
          )
          expect(result.outputs.status).to eq :new_signin_required
        end
      end

      context "happy path where authentication is added" do
        before(:each) do
          SecurityLog.create! user: current_user, remote_ip: '127.0.0.1',
                              event_type: :sign_in_successful, event_data: {}
        end

        it "adds the authentication, adds the auth email, returns :authentication_added" do
          result = handle(
            request: MockOmniauthRequest.new(
              "google_oauth2", "uid", { email: "joe@joe.com" }, 'add' => 'true'
            )
          )
          expect(result.outputs.status).to eq :authentication_added
          authentication = current_user.authentications.reload.first
          expect(authentication.provider).to eq "google_oauth2"
          expect(authentication.uid).to eq "uid"
          expect(current_user.contact_infos.verified.map(&:value)).to contain_exactly("joe@joe.com")
        end
      end
    end
  end

  context 'user_most_recently_used' do

    it 'returns nil when no users' do
      expect(user_most_recently_used([])).to be_nil
    end

    it 'returns the user when there is only one' do
      user = Object.new
      expect(user_most_recently_used([user])).to eq user
    end

    context "multiple users" do
      before(:each) {
        @user1 = FactoryBot.create :user, created_at: 1.year.ago
        @user2 = FactoryBot.create :user, created_at: 1.year.ago

        @user1.update(updated_at: 1.month.ago)
        @user2.update(updated_at: 1.year.ago)

        @user3 = FactoryBot.create :user
        Timecop.freeze(2.months.ago) do
          SecurityLog.create! user: @user3, remote_ip: '127.0.0.1',
                              event_type: :sign_in_successful, event_data: {}
        end

        @user4 = FactoryBot.create :user, created_at: 2.years.ago, updated_at: 2.years.ago
        Timecop.freeze(1.day.ago) do
          SecurityLog.create! user: @user4, remote_ip: '127.0.0.1',
                              event_type: :sign_in_successful, event_data: {}
        end
      }


      it 'favors later updated_at' do
        expect(user_most_recently_used([@user1, @user2])).to eq @user1
      end

      it 'favors later created_at when updated_at equal' do
        @user2.updated_at = @user1.updated_at
        expect(user_most_recently_used([@user1, @user2])).to eq @user2
      end

      it 'favors log in over no log in' do
        expect(user_most_recently_used([@user4, @user1])).to eq @user4
      end

      it 'favors recent logins' do
        expect(user_most_recently_used([@user4, @user3])).to eq @user4
      end
    end
  end

  def user_most_recently_used(users)
    described_class.new.send(:user_most_recently_used, users)
  end

end
